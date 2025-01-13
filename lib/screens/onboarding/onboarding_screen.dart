import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import '../../models/user_details.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_overlay.dart';
import 'components/onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithKakao() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Kakao 로그인 시도
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          Logger.log("카카오톡으로 로그인 성공");
        } catch (e) {
          Logger.log("카카오톡 로그인 실패, 계정으로 로그인 시도: $e");
          if (!mounted) return;

          // 카카오톡 로그인 실패 시 계정으로 로그인
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        Logger.log("카카오 계정으로 로그인 성공");
      }

      // 2. 카카오 사용자 정보 획득
      final kakaoUser = await kakao.UserApi.instance.me();
      Logger.log("카카오 사용자 정보 획득 성공: ${kakaoUser.id}");

      // 3. UserDetails 객체 생성
      final userDetails = UserDetails(
        uid: kakaoUser.id.toString(),
        displayName:
            kakaoUser.kakaoAccount?.profile?.nickname ?? 'Unknown User',
        email: kakaoUser.kakaoAccount?.email ?? '',
        photoURL: kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '',
      );

      // 4. Firebase 인증 및 사용자 생성
      if (!mounted) return;

      final appUser = await _authService.loginWithKakao(context, userDetails);

      if (!mounted) return;

      if (appUser != null) {
        // 사용자 정보 설정
        final userProvider = context.read<UserProvider>();
        userProvider.setUser(appUser);

        // 홈 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      Logger.log("로그인 실패: $e");
      if (!mounted) return;

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 온보딩 콘텐츠
          OnboardingContent(
            onKakaoLoginTap: () => _signInWithKakao(),
          ),

          // 로딩 오버레이
          if (_isLoading)
            const LoadingOverlay(
              message: '로그인 중입니다...',
            ),
        ],
      ),
    );
  }
}
