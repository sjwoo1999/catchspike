// lib/services/meal_analysis_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import '../models/meal_record.dart';
import '../utils/logger.dart';
import 'firebase_service.dart';
import '../firebase/config/firebase_config.dart';
import 'package:flutter/foundation.dart';

class MealAnalysisService {
  static const _maxRetries = 3;
  static const _initialRetryDelay = Duration(seconds: 1);

  final FirebaseService _firebaseService;
  final FirebaseFunctions _functions;

  MealAnalysisService({
    FirebaseService? firebaseService,
    FirebaseFunctions? functions,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _functions = functions ?? _initializeFunctions();

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

  Future<void> analyzeAndSaveMealImage(
    String userId,
    MealRecord mealRecord,
  ) async {
    try {
      Logger.log('분석 시작: ${mealRecord.id}');
      Logger.log('이미지 URL: ${mealRecord.imageUrl}');

      // 1. URL 검증
      final imageUrl = mealRecord.imageUrl;
      if (!_isValidImageUrl(imageUrl)) {
        throw Exception('이미지 URL 형식이 올바르지 않습니다');
      }

      // 2. 상태 업데이트 - 분석 시작
      await _updateStatus(
        userId: userId,
        recordId: mealRecord.id,
        status: 'analyzing',
        message: '음식 인식 중...',
      );

      // 3. 이미지 분석 (재시도 로직 포함)
      final analysisResult = await _retryOperation(
        operation: () => _analyzeFoodImage(
          imageUrl: imageUrl,
          userId: userId,
          recordId: mealRecord.id,
        ),
        maxRetries: _maxRetries,
        delay: _initialRetryDelay,
      );

      Logger.log('분석 결과: ${analysisResult.length}개 항목 감지');

      // 4. 결과 저장
      final resultData = {
        'foodItems': analysisResult,
        'metadata': {
          'analyzedAt': DateTime.now().toIso8601String(),
          'imageUrl': imageUrl,
          'mealType': mealRecord.mealType,
        }
      };

      await _firebaseService.updateMealRecordStatus(
        userId,
        mealRecord.id,
        status: 'analysis_completed',
        analysisResult: resultData,
      );

      Logger.log('분석 완료 [recordId: ${mealRecord.id}]');
    } catch (e) {
      Logger.log('분석 실패: $e');
      await _handleError(e, userId, mealRecord.id);
      rethrow;
    }
  }

  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // HTTPS 프로토콜 검사
      if (uri.scheme != 'https') {
        Logger.log('잘못된 프로토콜: ${uri.scheme}');
        return false;
      }

      // Firebase Storage 호스트 검사
      if (uri.host != 'firebasestorage.googleapis.com') {
        Logger.log('잘못된 호스트: ${uri.host}');
        return false;
      }

      // 경로에 'meal_images' 포함 여부 검사
      if (!uri.path.contains('meal_images')) {
        Logger.log('잘못된 경로: ${uri.path}');
        return false;
      }

      // 필수 쿼리 파라미터 검사
      if (!uri.queryParameters.containsKey('alt') ||
          !uri.queryParameters.containsKey('token')) {
        Logger.log('필수 쿼리 파라미터 누락: ${uri.queryParameters.keys}');
        return false;
      }

      return true;
    } catch (e) {
      Logger.log('URL 파싱 실패: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _analyzeFoodImage({
    required String imageUrl,
    required String userId,
    required String recordId,
  }) async {
    try {
      Logger.log('이미지 분석 요청 시작');

      final callable = _functions.httpsCallable(
        'analyzeFoodImage',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final result = await callable.call({
        'imageUrl': imageUrl,
        'metadata': {
          'userId': userId,
          'recordId': recordId,
        }
      });

      _validateAnalysisResponse(result.data);
      return List<Map<String, dynamic>>.from(result.data['foodItems']);
    } on FirebaseFunctionsException catch (e) {
      Logger.log('Functions 호출 실패: ${e.code} - ${e.message}');
      throw _mapFunctionError(e);
    }
  }

  void _validateAnalysisResponse(dynamic data) {
    if (data == null) {
      throw Exception('분석 결과가 비어있습니다');
    }

    if (!data.containsKey('foodItems')) {
      throw Exception('응답에 foodItems가 없습니다');
    }

    if (data['foodItems'] is! List) {
      throw Exception('foodItems의 형식이 올바르지 않습니다');
    }
  }

  Future<T> _retryOperation<T>({
    required Future<T> Function() operation,
    required int maxRetries,
    required Duration delay,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxRetries || !_shouldRetry(e)) {
          rethrow;
        }

        final nextDelay = delay * attempts; // 지수 백오프
        Logger.log('재시도 $attempts/$maxRetries - $nextDelay 후 재시도');
        await Future.delayed(nextDelay);
      }
    }
  }

  bool _shouldRetry(dynamic error) {
    if (error is FirebaseFunctionsException) {
      return ['unavailable', 'deadline-exceeded', 'internal']
          .contains(error.code);
    }
    return false;
  }

  Exception _mapFunctionError(FirebaseFunctionsException e) {
    final message = switch (e.code) {
      'not-found' => 'Clarifai API를 사용할 수 없습니다',
      'invalid-argument' => '잘못된 요청 형식입니다',
      'internal' => '서버 내부 오류가 발생했습니다',
      'unavailable' => '서비스를 일시적으로 사용할 수 없습니다',
      _ => '분석 중 오류가 발생했습니다: ${e.message}',
    };
    return Exception(message);
  }

  Future<void> _handleError(
    dynamic error,
    String userId,
    String recordId,
  ) async {
    final message = error is FirebaseFunctionsException
        ? _mapFunctionError(error).toString()
        : error.toString();

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
