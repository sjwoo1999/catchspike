const { initializeApp, cert } = require("firebase-admin/app");
// const { getFirestore } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { getAuth } = require("firebase-admin/auth");
const { Storage } = require("@google-cloud/storage");
const axios = require("axios");
require("dotenv").config();

// Firebase Admin Initialization
const serviceAccount = require("./serviceAccountKey.json");
initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth();
// const db = getFirestore();
const storage = new Storage();

// Function Global Options
setGlobalOptions({
  region: process.env.FUNCTION_REGION || "asia-northeast3",
  memory: process.env.FUNCTION_MEMORY || "512MB",
  maxInstances: 10,
  timeoutSeconds: 60,
});

// Google Cloud Storage to Base64 Conversion
async function getImageAsBase64(bucketName, fileName) {
  try {
    const bucket = storage.bucket(bucketName);
    const file = bucket.file(fileName);
    const [fileExists] = await file.exists();

    if (!fileExists) {
      throw new Error(`File does not exist: ${fileName}`);
    }

    const [fileBuffer] = await file.download();
    const image = Buffer.from(fileBuffer).toString("base64");
    // console.log("Image successfully converted to Base64 format.");
    return image;
  } catch (error) {
    // console.error("Error during image download or conversion:", error);
    throw new Error("Failed to download or convert image to Base64.");
  }
}

// YOLOv7 API Call to analyze the image
async function analyzeImageWithYOLOv7(imageUrl) {
  try {
    // YOLOv7 서버의 엔드포인트
    const yolov7Endpoint = process.env.YOLOV7_API_ENDPOINT;

    const response = await axios.post(
      yolov7Endpoint,
      { imageUrl }, // 이미지 URL을 서버에 전달
      {
        headers: {
          "Content-Type": "application/json",
        },
      },
    );

    if (response.status !== 200) {
      throw new Error(`YOLOv7 요청 실패: 상태 코드 ${response.status}`);
    }

    // console.log("YOLOv7 분석 성공:", response.data);
    return response.data;
  } catch (error) {
    // console.error("YOLOv7 이미지 분석 중 오류 발생:", error);
    throw new Error("YOLOv7 분석 실패");
  }
}

// OpenAI Thread Creation
async function createThread() {
  try {
    const response = await axios.post(
      "https://api.openai.com/v1/threads",
      {},
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );
    const threadId = response.data.id;
    // console.log("Thread created successfully:", threadId);
    return threadId;
  } catch (error) {
    // console.error("Failed to create thread:", error);
    throw error;
  }
}

// OpenAI Run Creation
async function createRun(threadId, assistantId) {
  try {
    const response = await axios.post(
      `https://api.openai.com/v1/threads/${threadId}/runs`,
      {
        assistant_id: assistantId,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );
    const runId = response.data.id;
    // console.log("Run created successfully:", runId);
    return runId;
  } catch (error) {
    console.error("Failed to create run:", error);
    throw error;
  }
}

// OpenAI Message Creation
async function createMessage(threadId, runId, base64Image, mealType) {
  try {
    const response = await axios.post(
      `https://api.openai.com/v1/threads/${threadId}/runs/${runId}/messages`,
      {
        role: "user",
        content: `Analyze the following meal image: ${base64Image} for meal type: ${mealType}`,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );
    //console.log("Message created successfully:", response.data);
    return response.data;
  } catch (error) {
    console.error("Failed to create message:", error);
    throw error;
  }
}

// analyzeFoodImage Cloud Function
exports.analyzeFoodImage = onRequest(
  {
    cors: true,
    maxInstances: 10,
    timeoutSeconds: 60,
    memory: "512MB",
  },
  async (req, res) => {
    // console.log("🔍 analyzeFoodImage invoked:", { data: req.body });

    if (!req.headers.authorization) {
      console.warn("⚠️ Unauthorized access attempt detected");
      return res.status(401).send({
        error: "unauthenticated",
        message: "Authentication required.",
      });
    }

    const { bucketName, fileName, mealType } = req.body;

    if (!bucketName || !fileName) {
      console.warn("⚠️ Missing image data information");
      return res.status(400).send({
        error: "invalid-argument",
        message: "Image file path is required.",
      });
    }

    try {
      // Get image from Google Cloud Storage
      const base64Image = await getImageAsBase64(bucketName, fileName);

      // Analyze image with YOLOv7
      const yoloResult = await analyzeImageWithYOLOv7(
        `gs://${bucketName}/${fileName}`,
      );

      // Create OpenAI thread
      const threadId = await createThread();

      // Create OpenAI run
      const runId = await createRun(threadId, process.env.OPENAI_ASSISTANT_ID);

      // Create message to analyze the image using OpenAI
      const openAIResult = await createMessage(
        threadId,
        runId,
        base64Image,
        mealType,
      );

      // Merge YOLOv7 and OpenAI results
      const result = {
        yolo_analysis: yoloResult,
        openai_analysis: openAIResult,
      };

      // console.log("✅ Image analysis successful:", result);
      return res.status(200).send(result);
    } catch (error) {
      console.error("❌ Error during image analysis:", error);
      return res.status(500).send({
          error: "internal",
          message: "Image analysis failed",
      });
    }
  },
);

// getCustomToken Cloud Function
exports.getCustomToken = onRequest(async (req, res) => {
  const { id, email, nickname, profileImageUrl } = req.body;

  if (!id || !email || !nickname) {
    return res.status(400).json({
      error: "missing_fields",
      message: "Required fields are missing.",
    });
  }

  // ✅ UID 변환 방식을 ":" → "_" 로 변경하여 Firestore 규칙과 일치하도록 함
  const sanitizedUid = `kakao_${id.replace(/[^a-zA-Z0-9]/g, "_")}`;

  try {
    await auth.getUser(sanitizedUid).catch(async (error) => {
      if (error.code === "auth/user-not-found") {
        return auth.createUser({
          uid: sanitizedUid,
          email,
          displayName: nickname,
          photoURL: profileImageUrl,
        });
      }
      throw error;
    });

    await auth.updateUser(sanitizedUid, {
      displayName: nickname,
      photoURL: profileImageUrl,
    });

    const customToken = await auth.createCustomToken(sanitizedUid);

    return res.status(200).json({ token: customToken });
  } catch (error) {
    console.error("❌ Error creating custom token:", error);
    return res.status(500).json({
      error: "internal_error",
      message: error.message,
    });
  }
});


// healthCheck Cloud Function
exports.healthCheck = onRequest(
  {
    cors: true,
    maxInstances: 5,
  },
  (req, res) => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "GET");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.set("Access-Control-Max-Age", "3600");
      return res.status(204).send("");
    }

    if (req.method !== "GET") {
      return res.status(405).json({
        error: "method_not_allowed",
        message: "Only GET method is allowed.",
      });
    }

    return res.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
      region: process.env.FUNCTION_REGION || "asia-northeast3",
    });
  },
);
