import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import '../../models/user_details.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';
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
      // 1. Kakao login
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          Logger.log("카카오톡으로 로그인 성공");
        } catch (e) {
          Logger.log("카카오톡 로그인 실패, 계정으로 로그인 시도: $e");
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        Logger.log("카카오 계정으로 로그인 성공");
      }

      // 2. Get Kakao user info
      final kakaoUser = await kakao.UserApi.instance.me();
      Logger.log("카카오 사용자 정보 획득 성공: ${kakaoUser.id}");

      // 3. Create UserDetails object
      final userDetails = UserDetails(
        uid: kakaoUser.id.toString(),
        displayName:
            kakaoUser.kakaoAccount?.profile?.nickname ?? 'Unknown User',
        email: kakaoUser.kakaoAccount?.email ?? '',
        photoURL: kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '',
      );

      // 4. Firebase authentication and user creation
      final appUser = await _authService.loginWithKakao(context, userDetails);

      if (!mounted) return;

      if (appUser != null) {
        await Provider.of<UserProvider>(context, listen: false)
            .setUser(appUser);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      Logger.log("로그인 실패: $e");
      if (!mounted) return;

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
          OnboardingContent(
            onKakaoLoginTap: _signInWithKakao,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
