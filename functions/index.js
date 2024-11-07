// index.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { ClarifaiStub, grpc } = require('clarifai-nodejs-grpc');
const { getAuth } = require('firebase-admin/auth');
require('dotenv').config();

// 서비스 계정 초기화
const serviceAccount = require('./serviceAccountKey.json');

// Firebase Admin 초기화
initializeApp({
  credential: cert(serviceAccount)
});

const auth = getAuth();
const db = getFirestore();

// 함수의 글로벌 옵션 설정
setGlobalOptions({
  region: process.env.FUNCTION_REGION || 'asia-northeast3',
  memory: process.env.FUNCTION_MEMORY || '512MB',
  maxInstances: 10,
  timeoutSeconds: 60
});

// Clarifai 설정
const PAT = process.env.CLARIFAI_PAT;
const USER_ID = 'clarifai';
const APP_ID = 'main';
const MODEL_ID = 'food-item-recognition';
const MODEL_VERSION_ID = '1d5fd481e0cf4826aa72ec3ff049e044';

// 공통 gRPC 호출 설정 및 오류 처리
async function callClarifaiAPI(imageUrl) {
  const stub = ClarifaiStub.grpc();
  const metadata = new grpc.Metadata();
  metadata.set('authorization', `Key ${PAT}`);

  return new Promise((resolve, reject) => {
    stub.PostModelOutputs({
      user_app_id: {
        user_id: USER_ID,
        app_id: APP_ID
      },
      model_id: MODEL_ID,
      version_id: MODEL_VERSION_ID,
      inputs: [
        {
          data: {
            image: {
              url: imageUrl,
              allow_duplicate_url: true
            }
          }
        }
      ]
    }, metadata, (err, response) => {
      if (err) {
        console.error('❌ Clarifai API 호출 오류:', err);
        return reject(new Error('Clarifai API 호출 중 오류가 발생했습니다.'));
      }
      if (response.status.code !== 10000) {
        console.error('❌ Clarifai API 응답 오류:', response.status);
        return reject(new Error(`Clarifai API 응답 오류: ${response.status.description}`));
      }
      resolve(response);
    });
  });
}

// analyzeFoodImage 함수
exports.analyzeFoodImage = onRequest({
  cors: true,
  maxInstances: 10,
  timeoutSeconds: 30,
  memory: '256MB'
}, async (req, res) => {
  console.log('🔍 analyzeFoodImage 호출됨:', { data: req.body });

  // 인증 상태 확인
  if (!req.headers.authorization) {
    console.warn('⚠️ 비인증 사용자 접근 시도');
    return res.status(401).send({ error: 'unauthenticated', message: '인증이 필요합니다.' });
  }

  const { imageUrl } = req.body;

  if (!imageUrl) {
    console.warn('⚠️ 이미지 URL 누락');
    return res.status(400).send({ error: 'invalid-argument', message: '이미지 URL이 필요합니다.' });
  }

  try {
    const clarifaiResponse = await callClarifaiAPI(imageUrl);
    const output = clarifaiResponse.outputs[0];
    const concepts = output.data.concepts;

    const foodItems = concepts
      .filter(concept => concept.value > 0.5)
      .map(concept => ({
        name: concept.name,
        value: concept.value
      }));

    console.log('✅ 이미지 분석 성공:', foodItems);
    return res.status(200).send({ foodItems });
  } catch (error) {
    console.error('❌ 이미지 분석 중 오류 발생:', error);
    return res.status(500).send({ error: 'internal', message: '이미지 분석 실패' });
  }
});

// getCustomToken 함수
exports.getCustomToken = onRequest({
  cors: true,
  maxInstances: 10,
  timeoutSeconds: 30,
  memory: '256MB'
}, async (req, res) => {
  try {
    // CORS preflight 처리
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      res.set('Access-Control-Max-Age', '3600');
      return res.status(204).send('');
    }

    if (req.method !== 'POST') {
      return res.status(405).json({
        error: 'method_not_allowed',
        message: 'POST 메소드만 허용됩니다.'
      });
    }

    const { id, email, nickname, profileImageUrl } = req.body;

    // 필수 필드 검증
    if (!id || !email || !nickname) {
      return res.status(400).json({
        error: 'missing_fields',
        message: '필수 필드가 누락되었습니다.',
        required: ['id', 'email', 'nickname'],
        received: { id, email, nickname }
      });
    }

    const uid = `kakao:${id}`;

    // 사용자 생성 또는 업데이트
    await auth.getUser(uid).catch(async (error) => {
      if (error.code === 'auth/user-not-found') {
        return auth.createUser({
          uid,
          email,
          displayName: nickname,
          photoURL: profileImageUrl
        });
      }
      throw error;
    });

    // 사용자 정보 업데이트
    await auth.updateUser(uid, {
      displayName: nickname,
      photoURL: profileImageUrl
    });

    // Firestore에 사용자 정보 저장
    await db.collection('users').doc(uid).set({
      email,
      nickname,
      profileImageUrl,
      provider: 'kakao',
      updatedAt: new Date()
    }, { merge: true });

    // Custom Token 생성
    const customToken = await auth.createCustomToken(uid);

    return res.status(200).json({
      token: customToken,
      status: 'success'
    });
  } catch (error) {
    console.error('❌ 토큰 생성 중 오류 발생:', error);

    const errorResponse = {
      error: error.code || 'internal_error',
      message: error.message || '서버 오류가 발생했습니다.'
    };

    if (error.code === 'auth/email-already-exists') {
      errorResponse.message = '이미 사용 중인 이메일입니다.';
    }

    return res.status(error.code ? 400 : 500).json(errorResponse);
  }
});

// healthCheck 함수
exports.healthCheck = onRequest({
  cors: true,
  maxInstances: 5
}, (req, res) => {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    return res.status(204).send('');
  }

  if (req.method !== 'GET') {
    return res.status(405).json({
      error: 'method_not_allowed',
      message: 'GET 메소드만 허용됩니다.'
    });
  }

  return res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    region: process.env.FUNCTION_REGION || 'asia-northeast3'
  });
});
