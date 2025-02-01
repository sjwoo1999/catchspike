// lib/services/auth_service.dart

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
    final customTokenUrl = dotenv.env['GET_CUSTOM_TOKEN_URL'];
    //final googleApiKey = dotenv.env['GOOGLE_API_KEY'];
    Logger.log("현재 Custom Token URL 설정: $customTokenUrl");
    //Logger.log("현재 Google API Key 설정: $googleApiKey");
  }

  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<app_user.User?> loginWithKakao(
      BuildContext context, UserDetails userDetails) async {
    try {
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setLoading(true);
      }

      if (!await kakao.AuthApi.instance.hasToken()) {
        throw kakao.KakaoClientException(
          kakao.ClientErrorCause.tokenNotFound,
          'Failed to find Kakao authentication token',
        );
      }

      final tokenData = await getFirebaseCustomToken(
        userDetails.uid,
        userDetails.email ?? '',
        userDetails.displayName,
        userDetails.photoURL ?? '',
      );
      final customToken = tokenData["customToken"]!;
      final sanitizedUid = tokenData["sanitizedUid"]!;

      Logger.log("Firebase 커스텀 토큰 획득 성공");

      final userCredential =
          await _firebaseAuth.signInWithCustomToken(customToken);

      if (userCredential.user != null) {
        // ✅ Firebase 인증 후, UID 검증
        if (userCredential.user!.uid != "kakao_${userDetails.uid}") {
          throw Exception(
              "Firebase 인증 후 UID 불일치! (${userCredential.user!.uid} ≠ kakao_${userDetails.uid})");
        }

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

  Future<Map<String, String>> getFirebaseCustomToken(
      String id, String email, String nickname, String profileImageUrl) async {
    if (dotenv.env['GET_CUSTOM_TOKEN_URL']?.isEmpty ?? true) {
      throw Exception('Custom Token URL이 설정되지 않았습니다. (.env 파일 확인 필요)');
    }

    final url = Uri.parse(dotenv.env['GET_CUSTOM_TOKEN_URL']!);
    final sanitizedUid = "kakao_${id.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}";

    final requestBody = {
      "id": id,
      "uid": sanitizedUid, // ✅ 변환된 UID 전달
      "email": email,
      "nickname": nickname,
      "profileImageUrl": profileImageUrl,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      Logger.log("Custom Token 요청 실패: ${response.body}");
      throw Exception('Custom Token 요청 실패');
    }

    final customToken = json.decode(response.body)['token'];
    return {"customToken": customToken, "sanitizedUid": sanitizedUid};
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
