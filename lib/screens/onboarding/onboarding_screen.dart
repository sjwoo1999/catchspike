import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    as kakao_user; // 별칭 추가
import '../../providers/user_provider.dart';
import '../../models/users.dart' as app_user;
import '../../services/auth_service.dart';
import '../../models/user_details.dart';
import '../../utils/logger.dart';
import 'components/onboarding_content.dart';

class OnboardingScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  OnboardingScreen({super.key});

  Future<void> _signInWithKakao(BuildContext context) async {
    try {
      // 1. 카카오 로그인
      kakao_user.OAuthToken token;
      if (await kakao_user.isKakaoTalkInstalled()) {
        try {
          token = await kakao_user.UserApi.instance.loginWithKakaoTalk();
          Logger.log("카카오톡으로 로그인 성공");
        } catch (e) {
          Logger.log("카카오톡 로그인 실패, 계정으로 로그인 시도: $e");
          if (!context.mounted) return;
          token = await kakao_user.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao_user.UserApi.instance.loginWithKakaoAccount();
        Logger.log("카카오 계정으로 로그인 성공");
      }

      // 2. 카카오 사용자 정보 획득
      final kakaoUser = await kakao_user.UserApi.instance.me();
      Logger.log("카카오 사용자 정보 획득 성공: ${kakaoUser.id}");

      // 3. UserDetails 객체 생성
      final userDetails = UserDetails(
        uid: kakaoUser.id.toString(),
        displayName:
            kakaoUser.kakaoAccount?.profile?.nickname ?? 'Unknown User',
        email: kakaoUser.kakaoAccount?.email ?? '', // 널 체크 후 기본값 설정
        photoURL: kakaoUser.kakaoAccount?.profile?.profileImageUrl ??
            '', // 널 체크 후 기본값 설정
      );

      if (!context.mounted) return;

      // 4. Firebase 인증 및 사용자 생성
      final appUser = await _authService.loginWithKakao(userDetails);

      if (!context.mounted) return;

      if (appUser != null) {
        await Provider.of<UserProvider>(context, listen: false)
            .setUser(appUser);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      Logger.log("로그인 실패: $e");
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingContent(
        onKakaoLoginTap: () => _signInWithKakao(context),
      ),
    );
  }
}
