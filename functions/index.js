const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
require('dotenv').config();

// Firebase Admin SDK 초기화
try {
  const serviceAccount = {
    projectId: process.env.PROJECT_ID,
    clientEmail: process.env.CLIENT_EMAIL,
    privateKey: process.env.PRIVATE_KEY.replace(/\\n/g, '\n'),
  };

  console.log('Service Account 정보 확인:', {
    projectId: serviceAccount.projectId,
    clientEmail: serviceAccount.clientEmail,
    hasPrivateKey: !!serviceAccount.privateKey,
  });

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  console.log('Firebase Admin 초기화 성공');
} catch (error) {
  console.error('Firebase Admin 초기화 실패:', error);
  if (error.code === 'app/duplicate-app') {
    console.log('Firebase Admin이 이미 초기화되어 있습니다.');
  } else {
    console.error('초기화 오류 상세:', error.message);
    throw error;
  }
}


// getCustomToken 함수
exports.getCustomToken = onRequest(
  { 
    region: 'us-central1',
    memory: '256MiB',
    timeoutSeconds: 60,
  }, 
  async (req, res) => {
    return cors(req, res, async () => {
      console.log('토큰 생성 요청 시작:', new Date().toISOString());

      // 메소드 체크
      if (req.method !== 'POST') {
        return res.status(405).json({
          success: false,
          error: 'Method Not Allowed',
          message: 'POST 요청만 허용됩니다.'
        });
      }

      try {
        const auth = req.body;
        console.log('요청 데이터:', JSON.stringify(auth));

        // 입력 데이터 검증
        if (!auth || typeof auth !== 'object') {
          throw new Error('유효하지 않은 요청 데이터');
        }

        const userId = auth.id || auth.kakaoId || auth.uid;
        if (!userId) {
          throw new Error('사용자 ID가 필요합니다');
        }

        // Custom Claims 설정
        const customClaims = {
          email: auth.email || '',
          displayName: auth.nickname || '',
          photoURL: auth.profileImageUrl || '',
          provider: 'kakao'
        };

        // Custom Token 생성
        const token = await admin.auth().createCustomToken(userId, customClaims);
        console.log('커스텀 토큰 생성 성공:', userId);

        // 사용자 존재 여부 확인 및 생성
        try {
          await admin.auth().getUser(userId);
          console.log('기존 사용자 확인:', userId);
        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            await admin.auth().createUser({
              uid: userId,
              email: auth.email,
              displayName: auth.nickname,
              photoURL: auth.profileImageUrl,
              disabled: false,
            });
            console.log('새 사용자 생성:', userId);
            
            // Custom Claims 설정
            await admin.auth().setCustomUserClaims(userId, customClaims);
          } else {
            throw error;
          }
        }

        // 성공 응답
        return res.status(200).json({
          success: true,
          token,
          message: '토큰이 성공적으로 생성되었습니다.'
        });

      } catch (error) {
        console.error('토큰 생성 오류:', error);
        
        return res.status(500).json({
          success: false,
          error: error.code || 'UNKNOWN_ERROR',
          message: error.message || '알 수 없는 오류가 발생했습니다.'
        });
      }
    });
  }
);

// Health check 함수
exports.healthCheck = onRequest(
  {
    region: 'us-central1',
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  (req, res) => {
    return cors(req, res, () => {
      console.log('Health check 요청:', new Date().toISOString());
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        runtime: 'nodejs18',
        config: {
          hasProjectId: !!functions.config().custom?.project_id,
          hasClientEmail: !!functions.config().custom?.client_email,
          hasPrivateKey: !!functions.config().custom?.private_key,
        }
      });
    });
  }
);