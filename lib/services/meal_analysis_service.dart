// lib/services/meal_analysis_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;

import '../models/meal_record.dart';
import '../models/analysis_result.dart';
import '../models/food_item.dart';

/// Firebase Storage 업로드 + Vision API 호출 + Firestore 캐싱
class MealAnalysisService {
  final String bucketName; // e.g. 'myapp-12345.appspot.com'
  final String firebaseAuthToken; // 필요 시
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String visionApiKey = dotenv.env['GCP_VISION_API_KEY'] ?? '';

  MealAnalysisService({
    required this.bucketName,
    required this.firebaseAuthToken,
  });

  /// (A) Firebase Storage에 이미지 업로드 (multipart)

  Future<String> uploadImageToFirebase(File imageFile, String userId) async {
    final sanitizedDate = DateTime.now().toIso8601String().split("T")[0];
    final fileName = "meal_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final filePath = "meal_images/$userId/$sanitizedDate/$fileName";

    final uploadUrl = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucketName/o?uploadType=multipart&name=$filePath',
    );

    // ✅ Firebase ID Token 가져오기
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Firebase 인증되지 않은 사용자입니다.");
    }

    final idToken = await currentUser.getIdToken(true);
    if (idToken == null) {
      throw Exception("Firebase ID Token을 가져오지 못했습니다.");
    }

    final request = http.MultipartRequest('POST', uploadUrl)
      ..headers['Authorization'] = 'Bearer $idToken'; // ✅ 인증 토큰 추가

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonData = jsonDecode(respStr);
      final name = jsonData['name'];
      final imageUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$name?alt=media';
      return imageUrl;
    } else {
      final error = await response.stream.bytesToString();
      throw Exception(
          'Firebase Storage 업로드 실패: ${response.statusCode}, $error');
    }
  }

  /// (B) Vision API: imageUri 방식을 사용 (URL -> 라벨/텍스트 등)
  Future<Map<String, dynamic>> callVisionAPI(String imageUrl) async {
    if (visionApiKey.isEmpty) {
      throw Exception('GCP_VISION_API_KEY가 설정되지 않았습니다.');
    }

    final endpoint = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$visionApiKey');
    final requestBody = {
      "requests": [
        {
          "image": {
            "source": {
              "imageUri": imageUrl,
            }
          },
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10},
            {"type": "TEXT_DETECTION", "maxResults": 5},
          ]
        }
      ]
    };

    final response = await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responses = data['responses'] as List<dynamic>;
      if (responses.isEmpty) return {};
      return responses[0] as Map<String, dynamic>;
    } else {
      throw Exception('Vision API 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// (C) Firestore 캐싱 로직
  ///  - 'vision_cache' 컬렉션에 문서 ID=imageUrl 로 저장
  Future<void> cacheVisionResult(
      String imageUrl, Map<String, dynamic> result) async {
    await firestore
        .collection('vision_cache')
        .doc(imageUrl)
        .set({'analysis': result}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadCachedVisionResult(String imageUrl) async {
    final doc = await firestore.collection('vision_cache').doc(imageUrl).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['analysis'] == null) return null;
    return Map<String, dynamic>.from(data['analysis']);
  }

  /// (D) Vision API 분석 (캐시 확인 후 호출)
  Future<Map<String, dynamic>> analyzeImageWithVision(String imageUrl) async {
    // 1) 캐시 확인
    final cached = await loadCachedVisionResult(imageUrl);
    if (cached != null) {
      return cached;
    }

    // 2) Vision API 호출
    final result = await callVisionAPI(imageUrl);

    // 3) 캐시에 저장
    await cacheVisionResult(imageUrl, result);

    return result;
  }

  /// (E) Vision API 결과 파싱 → 필요한 데이터만 추출
  ///     여기서는 실제 GI 정보가 없으므로, 시나리오상 GI 추출 로직이라 가정
  Map<String, dynamic> parseVisionResult(Map<String, dynamic> visionData) {
    final labels = (visionData['labelAnnotations'] ?? []) as List<dynamic>;
    final texts = (visionData['textAnnotations'] ?? []) as List<dynamic>;

    final topLabels = labels
        .map((e) => e['description'] as String?)
        .where((desc) => desc != null)
        .toList();

    String detectedText = '';
    if (texts.isNotEmpty) {
      detectedText = texts[0]['description'] ?? '';
    }

    // 여기에 GI 계산, FoodItem 매핑 로직 삽입 (Demo)
    // 실제론 라벨별 GI를 lookup해서 foodItems 만들 수 있음
    final foodItems = topLabels
        .map(
          (lbl) => {
            'name': lbl,
            'confidence': 0.9,
            'giIndex': 55.0, // 예시
          },
        )
        .toList();

    return {
      'labels': topLabels,
      'detectedText': detectedText,
      'foodItems': foodItems,
      'giInfo': 55, // 임의
    };
  }

  /// (F) AnalysisResult로 변환 (Demo)
  /// 실제 GI, nutrients, etc. 구성
  AnalysisResult buildAnalysisResult(
    Map<String, dynamic> parseData, {
    required String mealType,
    required String imageUrl,
  }) {
    final foodJsonList = parseData['foodItems'] as List<dynamic>? ?? [];
    final detectedFoods = foodJsonList
        .map((json) => FoodItem.fromJson(json as Map<String, dynamic>))
        .toList();

    // Demo로 NutritionAnalysis를 간단하게 삽입
    final nutrition = NutritionAnalysis(
      glycemicIndex: 55.0,
      calories: 300.0,
      GI: 55.0,
      estimatedGrams: 200.0,
    );

    final now = DateTime.now();
    final metadata = AnalysisMetadata(
      analyzedAt: now,
      mealType: mealType,
      imageUrl: imageUrl,
      modelVersion: 'v1.0',
    );

    return AnalysisResult(
      detectedFoods: detectedFoods,
      nutritionAnalysis: nutrition,
      comment: 'Demo analysis - GI = 55',
      overallHealthScore: 70,
      scoreBasis: 'Demo basis',
      metadata: metadata,
    );
  }

  /// (G) 이미지 업로드 + Vision 분석 + Firestore 저장 + MealRecord 업데이트
  Future<MealRecord> uploadAndAnalyzeMeal({
    required File imageFile,
    required String userId,
    required String mealType,
  }) async {
    // 1) Firebase Storage 업로드
    final imageUrl = await uploadImageToFirebase(imageFile, userId);

    // 2) Firestore에 MealRecord 생성 (pending_analysis 상태)
    final now = DateTime.now();
    final docRef = firestore.collection('meal_records').doc();
    final mealRecord = MealRecord(
      id: docRef.id,
      userId: userId,
      imageUrl: imageUrl,
      timestamp: now,
      mealType: mealType,
      status: 'pending_analysis',
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(mealRecord.toJson());

    // 3) Vision API 분석
    try {
      final rawVisionResult = await analyzeImageWithVision(imageUrl);
      final parsed = parseVisionResult(rawVisionResult);

      // 4) AnalysisResult 모델로 변환
      final analysisRes = buildAnalysisResult(
        parsed,
        mealType: mealType,
        imageUrl: imageUrl,
      );

      // 5) MealRecord 업데이트 (analysisResult, status=analysis_complete)
      final updatedRecord = mealRecord.copyWith(
        analysisResult: analysisRes,
        status: 'analysis_complete',
        analyzedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.update(updatedRecord.toJson());

      return updatedRecord;
    } catch (e) {
      // 6) 에러 발생 시 MealRecord 업데이트 (status=error)
      final errorRecord = mealRecord.copyWith(
        status: 'error',
        error: e.toString(),
        updatedAt: DateTime.now(),
      );
      await docRef.update(errorRecord.toJson());
      return errorRecord;
    }
  }
}
