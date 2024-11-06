// lib/firebase/config/firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class FirebaseConfig {
  static String? _openAiKey;

  /// OpenAI API Key를 가져옵니다.
  static String get openAiKey {
    if (_openAiKey != null) return _openAiKey!;
    _openAiKey = _getEnvOrThrow('OPENAI_API_KEY');
    return _openAiKey!;
  }

  static String _getEnvOrThrow(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key is not set or empty');
    }
    return value;
  }

  /// Firebase 플랫폼 별 설정
  static FirebaseOptions get currentPlatform {
    try {
      if (kIsWeb) {
        throw UnsupportedError(
          'Firebase configuration is not available for web platform.',
        );
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return FirebaseOptions(
            apiKey: _getEnvOrThrow('FIREBASE_ANDROID_API_KEY'),
            appId: _getEnvOrThrow('FIREBASE_ANDROID_APP_ID'),
            messagingSenderId: _getEnvOrThrow('FIREBASE_MESSAGING_SENDER_ID'),
            projectId: _getEnvOrThrow('FIREBASE_PROJECT_ID'),
            storageBucket: _getEnvOrThrow('FIREBASE_STORAGE_BUCKET'),
          );
        case TargetPlatform.iOS:
          return FirebaseOptions(
            apiKey: _getEnvOrThrow('FIREBASE_IOS_API_KEY'),
            appId: _getEnvOrThrow('FIREBASE_IOS_APP_ID'),
            messagingSenderId: _getEnvOrThrow('FIREBASE_MESSAGING_SENDER_ID'),
            projectId: _getEnvOrThrow('FIREBASE_PROJECT_ID'),
            storageBucket: _getEnvOrThrow('FIREBASE_STORAGE_BUCKET'),
            iosBundleId: _getEnvOrThrow('FIREBASE_IOS_BUNDLE_ID'),
          );
        default:
          throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.',
          );
      }
    } catch (e) {
      debugPrint('⚠️ Firebase configuration error: $e');
      rethrow;
    }
  }

  // Functions 설정
  static String get functionRegion =>
      dotenv.env['FUNCTION_REGION'] ?? 'asia-northeast3';

  static String get projectId => _getEnvOrThrow('FIREBASE_PROJECT_ID');

  static String get storageBucket => _getEnvOrThrow('FIREBASE_STORAGE_BUCKET');

  static String? _getFunctionUrl(String name) {
    final region = functionRegion;
    final project = projectId;
    if (region.isEmpty || project.isEmpty) {
      throw Exception('Function region or project ID is not set.');
    }
    return 'https://$region-$project.cloudfunctions.net/$name';
  }

  // Function URLs
  static String get customTokenUrl =>
      dotenv.env['GET_CUSTOM_TOKEN_URL'] ?? _getFunctionUrl('getCustomToken')!;

  static String get analyzeFoodImageUrl =>
      dotenv.env['ANALYZE_FOOD_IMAGE_URL'] ??
      _getFunctionUrl('analyzeFoodImage')!;

  static String get healthCheckUrl =>
      dotenv.env['HEALTH_CHECK_URL'] ?? _getFunctionUrl('healthCheck')!;

  // Kakao 설정
  static String get kakaoNativeKey => _getEnvOrThrow('KAKAO_NATIVE_APP_KEY');

  static String get kakaoJavaScriptKey =>
      dotenv.env['JAVASCRIPT_APP_KEY'] ?? '';

  /// AI 관련 설정
  static String? get openAiOrgId => dotenv.env['OPENAI_ORG_ID'];

  static String get openAiModel =>
      dotenv.env['OPENAI_MODEL'] ?? 'gpt-4-1106-preview';

  /// Firebase URL 유효성 검사를 위한 상수
  static const _validHosts = {
    'firebasestorage.googleapis.com',
    'cloudfunctions.net',
    'a.run.app'
  };

  /// Firebase URL 유효성 검사
  static bool isValidFirebaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' &&
          _validHosts.any((host) => uri.host.endsWith(host));
    } catch (_) {
      return false;
    }
  }

  /// Functions URL 유효성 검사
  static bool isValidFunctionUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' &&
          (uri.host.endsWith('cloudfunctions.net') ||
              uri.host.endsWith('a.run.app'));
    } catch (e) {
      debugPrint('⚠️ Functions URL 파싱 실패: $e');
      return false;
    }
  }

  /// Storage URL 유효성 검사
  static bool isValidStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final isFirebaseStorage = uri.host == 'firebasestorage.googleapis.com';
      final isCorrectBucket = uri.path.contains(storageBucket.split('.')[0]);
      final hasToken = uri.queryParameters.containsKey('token');
      final hasAltMedia = uri.queryParameters['alt'] == 'media';

      return uri.scheme == 'https' &&
          isFirebaseStorage &&
          isCorrectBucket &&
          hasToken &&
          hasAltMedia;
    } catch (e) {
      debugPrint('⚠️ Storage URL 파싱 실패: $e');
      return false;
    }
  }

  /// Functions URL 검증
  static void validateFunctionUrl(String name, String url) {
    debugPrint('🔍 Functions URL 검증: $name');
    if (!isValidFunctionUrl(url)) {
      debugPrint('⚠️ 잘못된 Functions URL: $url');
      throw Exception('유효하지 않은 Functions URL: $name');
    }
    debugPrint('✅ Functions URL 검증 완료: $name');
  }

  /// Storage URL 검증
  static void validateStorageUrl(String url) {
    debugPrint('🔍 Storage URL 검증');
    if (!isValidStorageUrl(url)) {
      debugPrint('⚠️ 잘못된 Storage URL: $url');
      throw Exception('유효하지 않은 Storage URL');
    }
    debugPrint('✅ Storage URL 검증 완료');
  }

  /// 환경변수 검증
  static Future<void> validateConfig() async {
    debugPrint('⚙️ 환경변수 검증 시작...');

    try {
      // Firebase 프로젝트 설정
      final projectId = _getEnvOrThrow('FIREBASE_PROJECT_ID');
      debugPrint('🔑 Project ID: $projectId');
      debugPrint('📦 Storage Bucket: $storageBucket');

      // Functions URLs 검증
      validateFunctionUrl('Custom Token', customTokenUrl);
      validateFunctionUrl('Analyze Food Image', analyzeFoodImageUrl);
      validateFunctionUrl('Health Check', healthCheckUrl);

      // Kakao 설정
      debugPrint('🔑 Kakao Native Key: $kakaoNativeKey');
      if (kakaoJavaScriptKey.isNotEmpty) {
        debugPrint('🔑 Kakao JavaScript Key: 설정됨');
      }

      // OpenAI 설정 검증
      try {
        final key = openAiKey;
        debugPrint('🔑 OpenAI API Key: ${key.substring(0, 5)}...');
        if (openAiOrgId != null) {
          debugPrint('🔑 OpenAI Organization ID: 설정됨');
        }
        debugPrint('🤖 OpenAI Model: $openAiModel');
      } catch (e) {
        debugPrint('⚠️ OpenAI 설정 오류: $e');
      }

      // 추가: Firebase Functions 접근성 확인
      await _checkFunctionAccessibility();

      debugPrint('✅ 모든 환경변수 검증 완료');
    } catch (e) {
      debugPrint('⚠️ 환경변수 검증 중 오류 발생: $e');
      rethrow;
    }
  }

  /// Firebase Functions의 접근성을 확인하는 메서드
  static Future<void> _checkFunctionAccessibility() async {
    debugPrint('🔍 Firebase Functions 접근성 확인 시작...');
    final functions = {
      'Custom Token': customTokenUrl,
      'Analyze Food Image': analyzeFoodImageUrl,
      'Health Check': healthCheckUrl,
    };

    for (var entry in functions.entries) {
      final name = entry.key;
      final url = entry.value;
      try {
        final response = await _retryHttpGet(url);
        if (response.statusCode == 200) {
          debugPrint('✅ $name 함수 접근 가능: ${response.statusCode}');
        } else {
          debugPrint('⚠️ $name 함수 접근 실패: ${response.statusCode}');
        }
      } on TimeoutException {
        debugPrint('⚠️ $name 함수 접근 실패: 요청 시간 초과');
      } catch (e) {
        debugPrint('⚠️ $name 함수 접근 실패: $e');
      }
    }
  }

  /// 네트워크 상태 확인
  static Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /// 재시도 로직 추가
  static Future<http.Response> _retryHttpGet(String url,
      {int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      if (!await _isNetworkAvailable()) {
        throw Exception('No network connection.');
      }
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
        return response;
      } catch (e) {
        if (attempt == retries - 1) {
          rethrow;
        }
        debugPrint('🔄 재시도 $attempt/$retries: $url');
        await Future.delayed(delay);
      }
    }
    throw Exception('Failed to GET $url after $retries attempts');
  }

  /// Functions 관련 메타데이터
  static Map<String, String> get functionsMetadata => {
        'region': functionRegion,
        'projectId': projectId,
        'environment': kDebugMode ? 'development' : 'production',
      };

  /// 환경변수 재로드
  static Future<void> reload() async {
    await dotenv.load();
    _openAiKey = null; // 캐시된 키를 초기화
    await validateConfig();
  }

  /// OpenAI 설정이 유효한지 확인
  static bool isOpenAIConfigured() {
    try {
      return openAiKey.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ OpenAI 설정 확인 실패: $e');
      return false;
    }
  }
}
