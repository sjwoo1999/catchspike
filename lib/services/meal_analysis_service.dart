import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal_record.dart';
import '../utils/logger.dart';
import 'firebase_service.dart';
import 'openai_service.dart';
import '../firebase/config/firebase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealAnalysisService {
  // 상수 정의
  static const _maxRetries = 3;
  static const _initialRetryDelay = Duration(seconds: 1);
  static const _functionTimeout = Duration(seconds: 30);

  // 서비스 인스턴스
  final FirebaseService _firebaseService;
  final FirebaseFunctions _functions;
  final OpenAIService _openAIService;
  final Connectivity _connectivity;

  // 생성자
  MealAnalysisService({
    FirebaseService? firebaseService,
    FirebaseFunctions? functions,
    OpenAIService? openAIService,
    Connectivity? connectivity,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _functions = functions ?? _initializeFunctions(),
        _openAIService = openAIService ?? OpenAIService(),
        _connectivity = connectivity ?? Connectivity();

  // Functions 초기화
  static FirebaseFunctions _initializeFunctions() {
    final functions = FirebaseFunctions.instanceFor(
      region: FirebaseConfig.functionRegion,
    );

    if (kDebugMode) {
      try {
        functions.useFunctionsEmulator('localhost', 5001);
        Logger.log('Functions 에뮬레이터 사용 중');
      } catch (e) {
        Logger.log('에뮬레이터 설정 실패: $e');
      }
    }

    return functions;
  }

  // 메인 분석 메서드
  Future<void> analyzeAndSaveMealImage(
    String userId,
    MealRecord mealRecord,
  ) async {
    try {
      Logger.log('분석 시작: ${mealRecord.id}');

      // 1. 네트워크 연결 확인
      if (!await _checkConnectivity()) {
        throw const NetworkException('인터넷 연결을 확인해주세요');
      }

      // 2. URL 검증
      final imageUrl = mealRecord.imageUrl;
      if (!_isValidImageUrl(imageUrl)) {
        throw const ValidationException('이미지 URL 형식이 올바르지 않습니다');
      }

      // 3. Firebase 인증 토큰 획득
      User? user = FirebaseAuth.instance.currentUser;
      String? idToken = await user?.getIdToken();
      if (idToken == null) {
        throw const NetworkException('사용자 인증 토큰을 가져올 수 없습니다');
      }

      // 4. 분석 시작 상태 업데이트
      await _updateStatus(
        userId: userId,
        recordId: mealRecord.id,
        status: 'analyzing',
        message: '음식 인식 중...',
      );

      // 5. 이미지 분석 (음식 인식)
      final foodItems = await _retryOperation(
        operation: () => _analyzeFoodImage(
          imageUrl: imageUrl,
          userId: userId,
          recordId: mealRecord.id,
          idToken: idToken,
        ),
        maxRetries: _maxRetries,
        delay: _initialRetryDelay,
      );

      Logger.log('이미지 분석 완료 - 감지된 음식: ${foodItems.length}개');

      // 6. 영양 분석
      Logger.log('영양 분석 시작');
      final nutritionAnalysis = await _openAIService.analyzeNutrition(
        foodItems: foodItems.map((item) => item['name'] as String).toList(),
        mealType: mealRecord.mealType,
      );

      // 7. 결과 데이터 통합
      final resultData = {
        'foodItems': foodItems,
        'nutrition': nutritionAnalysis,
        'metadata': {
          'analyzedAt': DateTime.now().toIso8601String(),
          'imageUrl': imageUrl,
          'mealType': mealRecord.mealType,
          'version': '1.0.0',
          'platform': defaultTargetPlatform.toString(),
        }
      };

      // 8. 최종 결과 저장
      await _firebaseService.updateMealRecordStatus(
        userId,
        mealRecord.id,
        status: 'analysis_completed',
        analysisResult: resultData,
      );

      Logger.log('분석 완료 [recordId: ${mealRecord.id}]');
    } on NetworkException catch (e) {
      Logger.log('네트워크 오류: $e');
      await _handleError(e, userId, mealRecord.id);
      rethrow;
    } on ValidationException catch (e) {
      Logger.log('검증 오류: $e');
      await _handleError(e, userId, mealRecord.id);
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      Logger.log('Functions 오류: ${e.code} - ${e.message}');
      await _handleError(_mapFunctionError(e), userId, mealRecord.id);
      rethrow;
    } catch (e) {
      Logger.log('분석 실패: 예상치 못한 오류: $e');
      await _handleError(e, userId, mealRecord.id);
      rethrow;
    }
  }

  // 네트워크 연결 확인
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      Logger.log('연결 상태 확인 실패: $e');
      return false;
    }
  }

  // URL 검증
  bool _isValidImageUrl(String url) {
    try {
      if (!FirebaseConfig.isValidStorageUrl(url)) {
        Logger.log('Firebase Storage URL 검증 실패');
        return false;
      }

      final uri = Uri.parse(url);

      // 경로 검증
      if (!uri.path.toLowerCase().contains('meal_images')) {
        Logger.log('잘못된 이미지 경로: meal_images 디렉토리가 아님');
        return false;
      }

      Logger.log('✅ 이미지 URL 검증 성공');

      // 필수 쿼리 파라미터 검증
      if (!uri.queryParameters.containsKey('token') ||
          !uri.queryParameters.containsKey('alt')) {
        Logger.log('필수 쿼리 파라미터 누락');
        return false;
      }

      Logger.log('✅ 필수 쿼리 파라미터 검증 성공');

      return true;
    } catch (e) {
      Logger.log('URL 검증 실패: $e');
      return false;
    }
  }

  // 이미지 분석
  Future<List<Map<String, dynamic>>> _analyzeFoodImage({
    required String imageUrl,
    required String userId,
    required String recordId,
    required String idToken, // 인증 토큰 추가
  }) async {
    try {
      Logger.log('이미지 분석 요청 시작');

      final url = Uri.parse(dotenv.env['ANALYZE_FOOD_IMAGE_URL'] ?? '');
      if (url.toString().isEmpty) {
        throw Exception('ANALYZE_FOOD_IMAGE_URL이 설정되지 않았습니다.');
      }

      final requestBody = {
        'imageUrl': imageUrl,
        'metadata': {
          'userId': userId,
          'recordId': recordId,
          'timestamp': DateTime.now().toIso8601String(),
          'platform': defaultTargetPlatform.toString(),
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken', // 인증 토큰 추가
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        Logger.log('Functions 응답 데이터: ${response.body}');
        final data = json.decode(response.body);
        _validateAnalysisResponse(data);
        return List<Map<String, dynamic>>.from(data['foodItems']);
      } else {
        Logger.log(
            'Functions 호출 실패: ${response.statusCode} - ${response.reasonPhrase}');
        throw FirebaseFunctionsException(
          code: 'http-error',
          message:
              'HTTP 요청 오류: ${response.statusCode} - ${response.reasonPhrase}',
          details: null,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      Logger.log('Functions 호출 실패: ${e.code} - ${e.message}');
      throw _mapFunctionError(e);
    } catch (e) {
      Logger.log('이미지 분석 실패: $e');
      rethrow;
    }
  }

  // 응답 검증
  void _validateAnalysisResponse(dynamic data) {
    if (data == null) {
      throw const ValidationException('분석 결과가 비어있습니다');
    }

    if (!data.containsKey('foodItems')) {
      throw const ValidationException('응답에 foodItems가 없습니다');
    }

    if (data['foodItems'] is! List) {
      throw const ValidationException('foodItems의 형식이 올바르지 않습니다');
    }

    final foodItems = data['foodItems'] as List;
    if (foodItems.isEmpty) {
      throw const ValidationException('음식을 인식하지 못했습니다');
    }
  }

  // 재시도 로직
  Future<T> _retryOperation<T>({
    required Future<T> Function() operation,
    required int maxRetries,
    required Duration delay,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxRetries) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        lastError = e;

        if (attempts >= maxRetries || !_shouldRetry(e)) {
          Logger.log('최대 재시도 횟수 초과 또는 재시도 불가능한 오류');
          rethrow;
        }

        final nextDelay = delay * attempts;
        Logger.log('재시도 $attempts/$maxRetries - $nextDelay 후 재시도');
        await Future.delayed(nextDelay);
      }
    }

    throw lastError;
  }

  // 재시도 가능 여부 확인
  bool _shouldRetry(dynamic error) {
    if (error is FirebaseFunctionsException) {
      return [
        'unavailable',
        'deadline-exceeded',
        'internal',
        'resource-exhausted',
      ].contains(error.code);
    }

    if (error is NetworkException) {
      return true;
    }

    return false;
  }

  // Functions 에러 매핑
  Exception _mapFunctionError(FirebaseFunctionsException e) {
    final message = switch (e.code) {
      'not-found' => 'Clarifai API를 사용할 수 없습니다',
      'invalid-argument' => '잘못된 요청 형식입니다',
      'internal' => '서버 내부 오류가 발생했습니다',
      'unavailable' => '서비스를 일시적으로 사용할 수 없습니다',
      'unauthenticated' => '인증이 필요합니다',
      'permission-denied' => '접근 권한이 없습니다',
      _ => '분석 중 오류가 발생했습니다: ${e.message}',
    };
    return FunctionException(message, e.code);
  }

  // 에러 처리
  Future<void> _handleError(
    dynamic error,
    String userId,
    String recordId,
  ) async {
    final message = switch (error) {
      NetworkException() => error.toString(),
      ValidationException() => error.toString(),
      FunctionException() => error.toString(),
      _ => '예상치 못한 오류가 발생했습니다: $error',
    };

    try {
      await _updateStatus(
        userId: userId,
        recordId: recordId,
        status: 'analysis_failed',
        message: message,
      );
    } catch (e) {
      Logger.log('상태 업데이트 실패: $e');
    }
  }

  // 상태 업데이트
  Future<void> _updateStatus({
    required String userId,
    required String recordId,
    required String status,
    String? message,
  }) async {
    await _firebaseService.updateMealRecordStatus(
      userId,
      recordId,
      status: status,
      error: message,
    );
    Logger.log('상태 업데이트: $status ${message ?? ""}');
  }
}

// 커스텀 예외 클래스들
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => message;
}

class FunctionException implements Exception {
  final String message;
  final String code;
  const FunctionException(this.message, this.code);
  @override
  String toString() => message;
}
