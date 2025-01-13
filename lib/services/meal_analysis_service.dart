import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img; // 이미지 압축을 위한 패키지
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../../firebase/config/firebase_config.dart';
import '../../models/meal_record.dart';
import '../../models/analysis_result.dart';
import '../../utils/logger.dart';
import '../../utils/exceptions.dart';
import 'firebase_service.dart';

class MealAnalysisService {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  final FirebaseService _firebaseService;
  final FirebaseFunctions _functions;
  final Connectivity _connectivity;
  final FirebaseFirestore _firestore;

  final String _apiKey;
  final String _model;

  MealAnalysisService({
    FirebaseService? firebaseService,
    FirebaseFunctions? functions,
    Connectivity? connectivity,
    FirebaseFirestore? firestore,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _functions = functions ?? _initializeFunctions(),
        _connectivity = connectivity ?? Connectivity(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _apiKey = FirebaseConfig.openAiKey,
        _model = FirebaseConfig.openAiModel {
    _validateOpenAISettings();
  }

  static FirebaseFunctions _initializeFunctions() {
    final functions = FirebaseFunctions.instanceFor(
      region: FirebaseConfig.functionRegion,
    );

    if (kDebugMode) {
      try {
        functions.useFunctionsEmulator('localhost', 5001);
        Logger.log('[INFO] Functions 에뮬레이터 사용 중');
      } catch (e) {
        Logger.log('[ERROR] 에뮬레이터 설정 실패: $e');
      }
    }

    return functions;
  }

  void _validateOpenAISettings() {
    if (_apiKey.isEmpty) {
      throw OpenAIException('API Key가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }
    if (_model.isEmpty) {
      throw OpenAIException('모델 설정이 잘못되었습니다. .env 파일에서 OPENAI_MODEL을 확인하세요.');
    }
    Logger.log('[INFO] OpenAI 설정 확인 완료: Model=$_model');
  }

  Future<Map<String, dynamic>> analyzeMealImage(
      String userId, MealRecord mealRecord, File imageFile) async {
    try {
      Logger.log('[INFO] YOLOv7 모델 호출을 통한 이미지 분석 중...');

      // Step 1: YOLOv7 Python 스크립트 호출을 통한 이미지 분석
      final yoloResult = await analyzeMealImageUsingYOLOv7(imageFile);
      Logger.log('[INFO] YOLOv7 분석 결과: $yoloResult');

      // Step 2: OpenAI Assistant API 호출을 통한 추가 이미지 분석
      Logger.log('[INFO] OpenAI Assistant API 호출을 통한 이미지 추가 분석 중...');
      final base64Image = compressAndEncodeImage(imageFile, quality: 50);
      final openAIResult = await analyzeMealImageUsingAssistant(base64Image);
      Logger.log('[INFO] OpenAI Assistant 분석 결과: $openAIResult');

      // 분석 결과 통합
      final combinedResult = mergeAnalysisResults(yoloResult, openAIResult);
      Logger.log('[INFO] 통합된 이미지 분석 결과: $combinedResult');

      return combinedResult;
    } catch (e) {
      Logger.log('[ERROR] 이미지 분석 중 오류 발생: $e');
      throw Exception('이미지 분석 실패: $e');
    }
  }

  // YOLOv7 Python 스크립트를 호출하여 이미지 분석하는 메서드
  Future<Map<String, dynamic>> analyzeMealImageUsingYOLOv7(
      File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final scriptPath = '${tempDir.path}/yolov7_inference.py';

      final result = await Process.run('python3', [scriptPath, imageFile.path]);

      if (result.exitCode != 0) {
        throw Exception('YOLOv7 스크립트 실행 실패: ${result.stderr}');
      }

      final output = jsonDecode(result.stdout);
      return output;
    } catch (e) {
      Logger.log('[ERROR] YOLOv7 이미지 분석 중 오류 발생: $e');
      throw Exception('YOLOv7 이미지 분석 실패: $e');
    }
  }

  // OpenAI Assistant를 사용하여 이미지 분석을 요청하는 메서드
  Future<Map<String, dynamic>> analyzeMealImageUsingAssistant(
      String base64Image) async {
    final endpoint = 'https://api.openai.com/v1/chat/completions';
    final messages = [
      {
        "role": "user",
        "content": "This is a base64 encoded image: $base64Image.\n"
            "Please describe the nutritional content and provide suggestions for improving the meal."
      }
    ];

    Logger.log('[DEBUG] OpenAI 분석 API 요청 준비 중...');

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1500,
          }),
        )
        .timeout(_defaultTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw OpenAIException(
        error['error']['message'] ?? 'OpenAI Assistant 요청 실패',
        code: error['error']['code'],
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('OpenAI API 응답이 예상한 JSON 형식이 아닙니다.');
    }
    return {'analysis': data['choices'][0]['message']['content']};
  }

  // 두 가지 분석 결과를 통합하는 메서드
  Map<String, dynamic> mergeAnalysisResults(
      Map<String, dynamic> yoloResult, Map<String, dynamic> openAIResult) {
    return {
      "yolo_analysis": yoloResult,
      "openai_analysis": openAIResult,
    };
  }

  // 이미지 압축 및 인코딩 메서드
  String compressAndEncodeImage(File imageFile, {int quality = 50}) {
    final image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      throw Exception('이미지를 디코딩할 수 없습니다.');
    }
    final compressedImageBytes = img.encodeJpg(image, quality: quality);
    return base64Encode(compressedImageBytes);
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      Logger.log('[DEBUG] 네트워크 상태 확인: Result=$result');
      return result != ConnectivityResult.none;
    } catch (e) {
      Logger.log('[ERROR] 연결 상태 확인 실패: $e');
      return false;
    }
  }
}
