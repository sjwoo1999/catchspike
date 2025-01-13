// lib/firebase/config/firebase_config.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../utils/logger.dart';

class FirebaseConfig {
  // Firebase 호스트 상수
  static const Set<String> _validHosts = {
    'firebasestorage.googleapis.com',
    'cloudfunctions.net',
    'a.run.app'
  };

  // 타임아웃 및 재시도 설정
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Kakao 설정
  static String get kakaoNativeKey => _getEnvOrThrow('KAKAO_NATIVE_APP_KEY');
  static String get kakaoJavaScriptKey => _getEnvOrThrow('JAVASCRIPT_APP_KEY');

  // OpenAI 설정
  static String get openAiKey => _getEnvOrThrow('OPENAI_API_KEY');
  static String get openAiModel =>
      const String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o');

  // Firebase Cloud Functions URLs
  static String get analyzeFoodImageUrl =>
      _getEnvOrThrow('ANALYZE_FOOD_IMAGE_URL');
  static String get customTokenUrl => _getEnvOrThrow('GET_CUSTOM_TOKEN_URL');
  static String get healthCheckUrl => _getEnvOrThrow('HEALTH_CHECK_URL');

  // Firebase 기본 설정
  static String get projectId => _getEnvOrThrow('FIREBASE_PROJECT_ID');
  static String get storageBucket => _getEnvOrThrow('FIREBASE_STORAGE_BUCKET');
  static String get messagingSenderId =>
      _getEnvOrThrow('FIREBASE_MESSAGING_SENDER_ID');

  // Functions 기본 설정
  static const String functionRegion = String.fromEnvironment(
    'FUNCTION_REGION',
    defaultValue: 'asia-northeast3',
  );

  // 개발 환경 여부
  static bool get isDevelopment {
    return !kReleaseMode &&
        const bool.fromEnvironment(
          'USE_FIREBASE_EMULATOR',
          defaultValue: false,
        );
  }

  // 플랫폼별 API Key
  static String get currentApiKey {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _getEnvOrThrow('FIREBASE_ANDROID_API_KEY');
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _getEnvOrThrow('FIREBASE_IOS_API_KEY');
      }
      throw UnsupportedError('지원되지 않는 플랫폼입니다.');
    } catch (e) {
      Logger.log('API Key 가져오기 실패: $e');
      rethrow;
    }
  }

  // 플랫폼별 App ID
  static String get currentAppId {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _getEnvOrThrow('FIREBASE_ANDROID_APP_ID');
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _getEnvOrThrow('FIREBASE_IOS_APP_ID');
      }
      throw UnsupportedError('지원되지 않는 플랫폼입니다.');
    } catch (e) {
      Logger.log('App ID 가져오기 실패: $e');
      rethrow;
    }
  }

  // iOS Bundle ID
  static String get iosBundleId => _getEnvOrThrow('FIREBASE_IOS_BUNDLE_ID');

  // Storage 베이스 URL
  static String get storageBaseUrl {
    if (isDevelopment) {
      return 'http://localhost:9199/$storageBucket';
    }
    return 'https://firebasestorage.googleapis.com/v0/b/$storageBucket';
  }

  // Functions 베이스 URL
  static String get functionsBaseUrl {
    if (isDevelopment) {
      return 'http://localhost:5001/$projectId/$functionRegion';
    }
    return 'https://$functionRegion-$projectId.cloudfunctions.net';
  }

  // 네트워크 상태 관리
  static final Connectivity _connectivity = Connectivity();

  // OpenAI 설정 검증
  static bool get isOpenAIConfigured {
    try {
      final key = openAiKey;
      return key.isNotEmpty && key.startsWith('sk-');
    } catch (e) {
      Logger.log('OpenAI 설정 확인 실패: $e');
      return false;
    }
  }

  // 환경변수 안전하게 가져오기
  static String _getEnvOrThrow(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      final error = '환경 변수를 찾을 수 없습니다: $key';
      Logger.log('⚠️ $error');
      throw ConfigurationException(error);
    }
    return value;
  }

  // Platform Specific Options
  static FirebaseOptions get currentPlatform {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return FirebaseOptions(
          apiKey: currentApiKey,
          appId: currentAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
        );
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return FirebaseOptions(
          apiKey: currentApiKey,
          appId: currentAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: iosBundleId,
        );
      }

      throw UnsupportedError('지원되지 않는 플랫폼입니다.');
    } catch (e) {
      Logger.log('Firebase 설정 생성 실패: $e');
      rethrow;
    }
  }

  /// 필수 설정 검증
  static void _validateRequiredConfigs() {
    Logger.log('🔍 필수 설정 검증 중...');

    final Map<String, Function()> requiredConfigs = {
      'Kakao Native Key': () => kakaoNativeKey,
      'OpenAI API Key': () => openAiKey,
      'Firebase Project ID': () => projectId,
      'Storage Bucket': () => storageBucket,
      'API Key': () => currentApiKey,
      'App ID': () => currentAppId,
    };

    for (final config in requiredConfigs.entries) {
      try {
        final value = config.value();
        if (value.isEmpty) {
          throw ConfigurationException('${config.key}가 비어있습니다.');
        }
        Logger.log('✓ ${config.key} 확인됨');
      } catch (e) {
        Logger.log('❌ ${config.key} 검증 실패: $e');
        throw ConfigurationException('${config.key} 설정이 올바르지 않습니다: $e');
      }
    }

    // OpenAI 키 형식 검증
    if (!openAiKey.startsWith('sk-')) {
      throw ConfigurationException('올바르지 않은 OpenAI API 키 형식');
    }

    Logger.log('✅ 모든 필수 설정 검증 완료');
  }

  /// 네트워크 연결 상태 확인
  static Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      Logger.log('네트워크 상태 확인 실패: $e');
      return false;
    }
  }

  /// HTTP 요청 with 재시도 로직
  static Future<T> _retryableRequest<T>({
    required Future<T> Function() request,
    int maxRetries = _maxRetries,
    Duration timeout = _defaultTimeout,
  }) async {
    if (!await _checkConnectivity()) {
      throw const NetworkException('인터넷 연결을 확인해주세요.');
    }

    int attempts = 0;
    late dynamic lastError;

    while (attempts < maxRetries) {
      try {
        return await request().timeout(timeout);
      } on TimeoutException {
        lastError = '요청 시간이 초과되었습니다.';
        Logger.log('⚠️ 요청 타임아웃 (시도 ${attempts + 1}/$maxRetries)');
      } on http.ClientException catch (e) {
        lastError = '서버 연결에 실패했습니다: ${e.message}';
        Logger.log('⚠️ 서버 연결 실패 (시도 ${attempts + 1}/$maxRetries): $e');
      } catch (e) {
        lastError = e;
        Logger.log('⚠️ 요청 실패 (시도 ${attempts + 1}/$maxRetries): $e');
      }

      attempts++;
      if (attempts < maxRetries) {
        await Future.delayed(_retryDelay * attempts);
      }
    }

    throw NetworkException('요청 실패 ($maxRetries회 시도): $lastError');
  }

  /// Functions 호출 메서드
  static Future<Map<String, dynamic>> callFunction(
    String url, {
    Map<String, dynamic>? data,
    Duration? timeout,
  }) async {
    try {
      final response = await _retryableRequest(
        timeout: timeout ?? _defaultTimeout,
        request: () async {
          final uri = Uri.parse(url);
          final response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Client-Version': '1.0.0',
              'X-Platform': defaultTargetPlatform.toString(),
            },
            body: data != null ? jsonEncode(data) : null,
          );

          if (response.statusCode != 200) {
            throw HttpException(
              '서버 오류: ${response.statusCode}',
              uri: uri,
            );
          }

          return jsonDecode(response.body) as Map<String, dynamic>;
        },
      );

      return response;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Functions 호출 실패: $e');
    }
  }

  /// Storage URL 생성
  static Future<String> createStorageUrl(String path) async {
    assert(path.isNotEmpty, 'Storage 경로는 비워둘 수 없습니다');

    final sanitizedPath = path.replaceAll(RegExp(r'[^\w/\-.]'), '_');

    try {
      if (isDevelopment) {
        return '$storageBaseUrl/o/${Uri.encodeComponent(sanitizedPath)}?alt=media';
      }

      return await _retryableRequest(
        request: () =>
            FirebaseStorage.instance.ref(sanitizedPath).getDownloadURL(),
      );
    } catch (e) {
      throw StorageException('Storage URL 생성 실패: $e');
    }
  }

  /// Storage 파일 업로드
  static Future<String> uploadFile(
    String path,
    File file, {
    Map<String, String>? metadata,
    void Function(double)? onProgress,
  }) async {
    try {
      if (!await _checkConnectivity()) {
        throw const NetworkException('인터넷 연결을 확인해주세요.');
      }

      final ref = FirebaseStorage.instance.ref(path);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: metadata,
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw StorageException('파일 업로드 실패: $e');
    }
  }

  /// 설정 검증
  static Future<void> validateConfig() async {
    try {
      Logger.log('🔍 Firebase 설정 검증 시작...');

      // 필수 설정 검증
      _validateRequiredConfigs();

      if (!await _checkConnectivity()) {
        throw const NetworkException('인터넷 연결을 확인해주세요.');
      }

      // Functions 연결 테스트
      await _testFunctionsConnection();

      // Firebase 초기화
      await Firebase.initializeApp(
        options: currentPlatform,
      );

      // 에뮬레이터 설정 (개발 환경인 경우)
      if (isDevelopment) {
        await _setupEmulators();
      }

      Logger.log('✅ Firebase 설정 검증 완료');
    } catch (e) {
      Logger.log('❌ Firebase 설정 검증 실패: $e');
      rethrow;
    }
  }

  /// Functions 연결 테스트
  static Future<void> _testFunctionsConnection() async {
    try {
      final response = await _retryableRequest(
        timeout: const Duration(seconds: 5),
        request: () => http.get(Uri.parse(healthCheckUrl)),
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Health check 실패: ${response.statusCode}',
          uri: Uri.parse(healthCheckUrl),
        );
      }

      Logger.log('✅ Functions 연결 테스트 성공');
    } catch (e) {
      throw NetworkException('Functions 연결 실패: $e');
    }
  }

  /// 에뮬레이터 설정
  static Future<void> _setupEmulators() async {
    try {
      Logger.log('🔧 Firebase 에뮬레이터 설정 시작...');

      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // await FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      // await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      Logger.log('✅ Firebase 에뮬레이터 설정 완료');
    } catch (e) {
      Logger.log('❌ Firebase 에뮬레이터 설정 실패: $e');
      rethrow;
    }
  }

  /// Functions 메타데이터 가져오기
  static Map<String, String> get functionsMetadata => {
        'region': functionRegion,
        'projectId': projectId,
        'environment': isDevelopment ? 'development' : 'production',
        'platform': defaultTargetPlatform.toString(),
        'appVersion':
            const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
      };

  /// Storage URL 검증 메서드를 클래스 내부로 이동
  static bool isValidStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // 개발 환경 체크
      if (isDevelopment && uri.host == 'localhost') {
        return uri.port == 9199;
      }

      // 기본 Firebase URL 검증
      if (!isValidFirebaseUrl(url)) return false;

      // Storage 전용 검증
      if (uri.host != 'firebasestorage.googleapis.com') {
        Logger.log('잘못된 Storage 호스트');
        return false;
      }

      // 버킷 검증
      if (!uri.path.contains(storageBucket)) {
        Logger.log('잘못된 Storage 버킷');
        return false;
      }

      // 필수 쿼리 파라미터 검증
      final hasRequiredParams = uri.queryParameters.containsKey('token') &&
          uri.queryParameters['alt'] == 'media';

      if (!hasRequiredParams) {
        Logger.log('필수 쿼리 파라미터 누락');
        return false;
      }

      return true;
    } catch (e) {
      Logger.log('Storage URL 검증 오류: $e');
      return false;
    }
  }

  /// Firebase URL 유효성 검사
  static bool isValidFirebaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' &&
          _validHosts.any((host) => uri.host.endsWith(host));
    } catch (e) {
      Logger.log('Firebase URL 검증 오류: $e');
      return false;
    }
  }
}

/// 유틸리티 익스텐션
extension FirebaseConfigUtils on FirebaseConfig {
  /// URL이 현재 프로젝트의 것인지 확인
  static bool isProjectUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains(FirebaseConfig.projectId) ||
          uri.path.contains(FirebaseConfig.projectId);
    } catch (e) {
      return false;
    }
  }

  /// Storage 경로 생성
  static String createStoragePath({
    required String userId,
    required String directory,
    String? fileName,
  }) {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final actualFileName =
        fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return '$directory/$userId/$date/$actualFileName';
  }

  /// Functions URL 생성
  static String createFunctionUrl(String functionName) {
    if (FirebaseConfig.isDevelopment) {
      return '${FirebaseConfig.functionsBaseUrl}/$functionName';
    }
    return 'https://$functionName-q5bokhkwja-du.a.run.app';
  }
}

/// 설정 리로더
class FirebaseConfigReloader {
  static Future<void> reload() async {
    try {
      Logger.log('🔄 Firebase 설정 리로드 시작...');

      // .env 파일 리로드
      await dotenv.load();

      // Firebase 재초기화
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );

      // 에뮬레이터 재설정 (개발 환경인 경우)
      if (FirebaseConfig.isDevelopment) {
        await FirebaseConfig._setupEmulators();
      }

      Logger.log('✅ Firebase 설정 리로드 완료');
    } catch (e) {
      Logger.log('❌ Firebase 설정 리로드 실패: $e');
      rethrow;
    }
  }
}

/// 타입 정의
typedef ProgressCallback = void Function(double progress);
typedef ErrorCallback = void Function(String error);
typedef SuccessCallback<T> = void Function(T result);

/// 커스텀 예외 클래스들
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

class ConfigurationException implements Exception {
  final String message;
  const ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
