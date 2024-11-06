// functions/index.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { ClarifaiStub, grpc } = require('clarifai-nodejs-grpc');
const { getAuth } = require('firebase-admin/auth');
const functions = require('firebase-functions');
const cors = require('cors')({ origin: true });
require('dotenv').config(); // 환경 변수를 dotenv로 관리합니다.

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
  memory: process.env.FUNCTION_MEMORY || '512MB'
});

// Clarifai 설정
const PAT = process.env.CLARIFAI_PAT;
const USER_ID = 'clarifai';
const APP_ID = 'main';
const MODEL_ID = 'food-item-recognition';
const MODEL_VERSION_ID = '1d5fd481e0cf4826aa72ec3ff049e044';

// analyzeFoodImage 함수
exports.analyzeFoodImage = onCall(async (data, context) => {
  console.log('🔍 analyzeFoodImage 호출됨:', { data, context });

  // 인증 상태 확인
  if (!context.auth) {
    console.warn('⚠️ 비인증 사용자 접근 시도:', context);
    throw new functions.https.HttpsError(
      'unauthenticated',
      '인증이 필요합니다.'
    );
  }

  const imageUrl = data.imageUrl;

  if (!imageUrl) {
    console.warn('⚠️ 이미지 URL 누락:', data);
    throw new functions.https.HttpsError(
      'invalid-argument',
      '이미지 URL이 필요합니다. 요청에 "imageUrl" 매개변수를 포함해주세요.'
    );
  }

  try {
    const stub = ClarifaiStub.grpc();
    const metadata = new grpc.Metadata();
    metadata.set('authorization', 'Key ' + PAT);

    const response = await new Promise((resolve, reject) => {
      stub.PostModelOutputs(
        {
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
        },
        metadata,
        (err, response) => {
          if (err) {
            console.error('Clarifai API 호출 오류:', err);
            reject(new functions.https.HttpsError('internal', 'Clarifai API 호출 오류'));
          } else if (response.status.code !== 10000) {
            console.error('Clarifai API 응답 오류:', response.status.description);
            reject(new functions.https.HttpsError('internal', 'Clarifai API 응답 오류: ' + response.status.description));
          } else {
            resolve(response);
          }
        }
      );
    });

    const output = response.outputs[0];
    const concepts = output.data.concepts;

    const foodItems = concepts.map((concept) => ({
      name: concept.name,
      value: concept.value
    }));

    console.log('✅ 이미지 분석 성공:', foodItems);
    return { foodItems };
  } catch (error) {
    console.error('❌ 이미지 분석 중 오류 발생:', error);
    throw new functions.https.HttpsError('internal', '이미지 분석 중 오류가 발생했습니다. 다시 시도해주세요.');
  }
});

// 사용자 생성 또는 토큰 가져오기 함수 리팩토링
async function getUserOrCreate(uid, email, nickname, profileImageUrl) {
  try {
    let userRecord;
    try {
      userRecord = await auth.getUser(uid);
      console.log('✅ 기존 사용자 확인:', userRecord.uid);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('🆕 사용자를 찾을 수 없음. 새 사용자 생성 중:', uid);
        const createUserParams = {
          uid,
          displayName: nickname,
          photoURL: profileImageUrl
        };
        if (email) createUserParams.email = email;

        userRecord = await auth.createUser(createUserParams);
        console.log('✅ 새 사용자 생성 성공:', userRecord.uid);
      } else {
        throw error;
      }
    }

    await auth.updateUser(uid, {
      displayName: nickname,
      photoURL: profileImageUrl
    });

    console.log('🔄 사용자 정보 업데이트 완료:', uid);
    return userRecord;
  } catch (error) {
    console.error('❌ 사용자 생성/갱신 중 오류 발생:', error);
    throw new functions.https.HttpsError('internal', '사용자 생성/갱신 중 오류가 발생했습니다.');
  }
}

// getCustomToken 함수
exports.getCustomToken = onRequest(async (req, res) => {
  console.log('🔍 getCustomToken 호출됨:', req.method, req.body);

  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('허용되지 않은 메소드입니다.');
    return;
  }

  const { id, email, nickname, profileImageUrl } = req.body;

  if (!id || !email || !nickname) {
    console.warn('⚠️ 필수 필드 누락:', { id, email, nickname });
    return res.status(400).json({
      error: '필수 필드가 누락되었습니다.',
      required: ['id', 'email', 'nickname'],
      received: { id, email, nickname }
    });
  }

  const uid = `kakao:${id}`;

  try {
    // 사용자 생성 또는 가져오기
    await getUserOrCreate(uid, email, nickname, profileImageUrl);

    // 사용자 정의 토큰 생성
    const customToken = await auth.createCustomToken(uid);
    console.log('✅ 사용자 정의 토큰 생성 성공:', uid);

    res.status(200).json({
      token: customToken,
      status: 'success'
    });
  } catch (error) {
    console.error('❌ 토큰 생성 중 오류 발생:', error);

    const errorResponse = {
      error: error.code || 'Internal Server Error',
      message: error.message || '서버 내부 오류가 발생했습니다.',
      code: error.code || 'unknown'
    };

    if (error.code === 'auth/email-already-exists') {
      errorResponse.message = '이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.';
    }

    res.status(error.code ? 400 : 500).json(errorResponse);
  }
});

// healthCheck 함수
exports.healthCheck = onRequest((req, res) => {
  console.log('🔍 healthCheck 호출됨:', req.method);
  res.status(200).send('OK');
});