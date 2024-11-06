// lib/widgets/custom_drawer.dart

import 'package:catchspike/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import '../providers/user_provider.dart';
import '../utils/global_keys.dart';
import '../services/auth_service.dart';
import '../models/users.dart' as app_user;
import '../models/user_details.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final bool isLoggedIn = userProvider.user != null;

          if (isLoggedIn) {
            return const LoggedInMenuContent();
          } else {
            return const LoggedOutMenuContent();
          }
        },
      ),
    );
  }
}

class LoggedInMenuContent extends StatefulWidget {
  const LoggedInMenuContent({super.key});

  @override
  LoggedInMenuContentState createState() => LoggedInMenuContentState();
}

class LoggedInMenuContentState extends State<LoggedInMenuContent> {
  late final UserProvider _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  Future<void> _logout() async {
    try {
      Navigator.pop(context);
      await kakao.UserApi.instance.logout();

      if (!mounted) return;
      _userProvider.clearUser();

      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('로그아웃 성공')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app_user.User? user = _userProvider.user;
    final bool isLoading = _userProvider.isLoading;

    if (isLoading) {
      return const Center(
          child: LoadingIndicator(
        primaryColor: Colors.white,
      ));
    }

    final String userName = user?.name ?? '사용자 이름';
    final String userEmail = user?.email ?? 'user@example.com';
    final String profileImageUrl =
        user?.profileImageUrl ?? 'assets/images/default_profile.png';

    return ListView(
      children: [
        Container(
          color: const Color(0xFFE30547),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                backgroundImage: profileImageUrl.startsWith('http')
                    ? NetworkImage(profileImageUrl)
                    : AssetImage(profileImageUrl) as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.account_circle),
          title: const Text('나의 계정'),
          onTap: () {
            Navigator.pop(context);
            // TODO: 계정 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('마이페이지'),
          onTap: () {
            Navigator.pop(context);
            // TODO: 마이페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: () {
            _logout(); // void 타입 에러 수정
          },
        ),
      ],
    );
  }
}

class LoggedOutMenuContent extends StatefulWidget {
  const LoggedOutMenuContent({super.key});

  @override
  State<LoggedOutMenuContent> createState() => LoggedOutMenuContentState();
}

class LoggedOutMenuContentState extends State<LoggedOutMenuContent> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _loginWithKakao() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final kakaoUser = await kakao.UserApi.instance.me();
      final userDetails = UserDetails(
        uid: kakaoUser.id.toString(),
        displayName:
            kakaoUser.kakaoAccount?.profile?.nickname ?? 'Unknown User',
        email: kakaoUser.kakaoAccount?.email ?? 'unknown@example.com',
        photoURL: kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '',
      );

      if (!mounted) return;
      final app_user.User? appUser =
          await _authService.loginWithKakao(context, userDetails);

      if (!mounted) return;
      if (appUser != null) {
        context.read<UserProvider>().setUser(appUser);
        Navigator.pop(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('로그인 성공')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
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
    return ListView(
      children: [
        Container(
          color: const Color(0xFFE30547),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    AssetImage('assets/images/default_profile.png'),
              ),
              const SizedBox(height: 16),
              const Text(
                '로그인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '카카오톡으로 3초만에 가입하세요',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isLoading ? null : () => _loginWithKakao(),
                child: _isLoading
                    ? const LoadingIndicator(
                        primaryColor: Colors.white,
                      )
                    : Image.asset(
                        'assets/images/kakao_login_medium_narrow.png',
                        fit: BoxFit.contain,
                        width: 200,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
