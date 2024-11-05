import 'package:flutter/material.dart';
import 'package:catchspike/models/users.dart' as app_user;
import 'package:catchspike/providers/user_provider.dart';
import 'package:catchspike/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_details.dart';
import 'firebase_service.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _logEnvironmentVariables();
  }

  void _logEnvironmentVariables() {
    final functionUrl = dotenv.env['FIREBASE_FUNCTION_URL'];
    final googleApiKey = dotenv.env['GOOGLE_API_KEY'];
    Logger.log("현재 Function URL 설정: $functionUrl");
    Logger.log("현재 Google API Key 설정: $googleApiKey");
  }

  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<app_user.User?> loginWithKakao(
      BuildContext context, UserDetails userDetails) async {
    try {
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setLoading(true);
      }

      // Check if kakao token exists first
      if (!await kakao.AuthApi.instance.hasToken()) {
        throw kakao.KakaoClientException(
          kakao.ClientErrorCause.tokenNotFound,
          'Failed to find Kakao authentication token', // 두 번째 필수 인자 추가
        );
      }

      final customToken = await getFirebaseCustomToken(
        userDetails.uid,
        userDetails.email ?? '',
        userDetails.displayName,
        userDetails.photoURL ?? '',
      );
      Logger.log("Firebase 커스텀 토큰 획득 성공");

      final userCredential =
          await _firebaseAuth.signInWithCustomToken(customToken);

      if (userCredential.user != null) {
        final user = app_user.User(
          id: userCredential.user!.uid,
          name: userDetails.displayName,
          email: userDetails.email,
          kakaoId: userDetails.uid,
          profileImageUrl: userDetails.photoURL,
          lastLoginAt: DateTime.now(),
        );

        await _firebaseService.saveUser(user);
        Logger.log("사용자 정보 Firebase 저장 성공: ${user.id}");

        return user;
      }

      Logger.log("Firebase 사용자 생성 실패");
      return null;
    } catch (e) {
      Logger.log("로그인 프로세스 실패: $e");
      if (e is kakao.KakaoClientException) {
        if (context.mounted) {
          await signOut(context);

          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          }
        }
      }
      rethrow;
    } finally {
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setLoading(false);
      }
    }
  }

  Future<String> getFirebaseCustomToken(
      String id, String email, String nickname, String profileImageUrl) async {
    try {
      final functionUrl = dotenv.env['FIREBASE_FUNCTION_URL'];
      Logger.log("Function URL 확인: $functionUrl");

      if (functionUrl == null || functionUrl.isEmpty) {
        throw Exception('Function URL이 설정되지 않았습니다. (.env 파일을 확인해주세요)');
      }

      final url = Uri.parse(functionUrl);
      Logger.log("토큰 요청 URL: $url");

      final requestBody = {
        "id": id,
        "email": email,
        "nickname": nickname,
        "profileImageUrl": profileImageUrl,
      };

      Logger.log("요청 데이터: ${json.encode(requestBody)}");

      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('토큰 요청 시간이 초과되었습니다.');
        },
      );

      Logger.log("토큰 요청 응답 상태 코드: ${response.statusCode}");
      Logger.log("토큰 요청 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['token'] != null) {
            return data['token'];
          }
          throw Exception('응답에 토큰이 없습니다: ${response.body}');
        } catch (e) {
          Logger.log("JSON 파싱 실패: $e");
          throw Exception('응답 데이터 처리 중 오류가 발생했습니다.');
        }
      }

      final errorMessage = _getErrorMessage(response.statusCode, response.body);
      throw Exception(errorMessage);
    } catch (e) {
      Logger.log("Firebase 커스텀 토큰 생성 실패: $e");
      rethrow;
    }
  }

  String _getErrorMessage(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다. 요청 데이터를 확인해주세요: $responseBody';
      case 401:
        return '인증되지 않은 요청입니다. 인증 설정을 확인해주세요.';
      case 404:
        return '요청한 Function을 찾을 수 없습니다. URL과 배포 상태를 확인해주세요.';
      case 429:
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 500:
        return '서버 내부 오류가 발생했습니다. 관리자에게 문의해주세요.';
      default:
        return '알 수 없는 오류가 발생했습니다. (상태 코드: $statusCode, 응답: $responseBody)';
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _firebaseAuth.signOut();
      Logger.log("Firebase 로그아웃 성공");

      try {
        if (await kakao.AuthApi.instance.hasToken()) {
          await kakao.UserApi.instance.logout();
          Logger.log("카카오 로그아웃 성공");
        }
      } catch (e) {
        Logger.log("카카오 로그아웃 실패: $e");
      }

      if (context.mounted) {
        await Provider.of<UserProvider>(context, listen: false).clearUser();
        Logger.log("로그아웃 프로세스 완료");
      }
    } catch (e) {
      Logger.log("로그아웃 실패: $e");
      rethrow;
    }
  }

  bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  firebase.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<bool> isKakaoLoggedIn() async {
    try {
      return await kakao.AuthApi.instance.hasToken();
    } catch (e) {
      Logger.log("카카오 로그인 상태 확인 실패: $e");
      return false;
    }
  }

  Future<bool> validateTokens(BuildContext context) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return false;
      }

      if (!await isKakaoLoggedIn()) {
        return false;
      }

      return true;
    } catch (e) {
      Logger.log("토큰 유효성 검사 실패: $e");
      return false;
    }
  }
}
