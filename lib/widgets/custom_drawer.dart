// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../providers/user_provider.dart';
import '../utils/global_keys.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          print('CustomDrawer rebuild');
          print('Provider에서 받은 user: ${userProvider.user?.id}');

          final bool isLoggedIn = userProvider.user != null;
          print('isLoggedIn: $isLoggedIn');

          if (isLoggedIn) {
            print('로그인된 상태 - 유저 ID: ${userProvider.user?.id}');
            return const LoggedInMenuContent();
          } else {
            print('로그아웃된 상태');
            return const LoggedOutMenuContent();
          }
        },
      ),
    );
  }
}

// 로그인된 상태의 메뉴 내용
class LoggedInMenuContent extends StatefulWidget {
  const LoggedInMenuContent({super.key});

  @override
  _LoggedInMenuContentState createState() => _LoggedInMenuContentState();
}

class _LoggedInMenuContentState extends State<LoggedInMenuContent> {
  late final UserProvider _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  Future<void> _logout() async {
    try {
      // 드로어를 먼저 닫기
      Navigator.pop(context);

      await UserApi.instance.logout();

      if (!mounted) return;
      _userProvider.clearUser();

      print('로그아웃 성공');
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('로그아웃 성공')),
      );
    } catch (e) {
      print('로그아웃 실패 $e');
      if (!mounted) return;

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _userProvider.user;

    final String userName = user?.kakaoAccount?.profile?.nickname ?? '사용자 이름';
    final String userEmail = user?.kakaoAccount?.email ?? 'user@example.com';
    final String profileImageUrl =
        user?.kakaoAccount?.profile?.profileImageUrl ??
            'assets/images/default_profile.png';

    return ListView(
      children: [
        Container(
          color: const Color(0xFFE30547), // #E30547 색상으로 변경
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
                        fontWeight: FontWeight.w500, // 글자 굵기 조정
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.normal, // 기본 굵기
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 메뉴 항목들
        ListTile(
          leading: const Icon(Icons.account_circle),
          title: const Text('나의 계정'),
          onTap: () {
            Navigator.pop(context);
            // 실제 페이지로 이동하는 코드 추가
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('마이페이지'),
          onTap: () {
            Navigator.pop(context);
            // 실제 페이지로 이동하는 코드 추가
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: _logout,
        ),
      ],
    );
  }
}

// 로그인되지 않은 상태의 메뉴 내용
class LoggedOutMenuContent extends StatefulWidget {
  const LoggedOutMenuContent({super.key});

  @override
  _LoggedOutMenuContentState createState() => _LoggedOutMenuContentState();
}

class _LoggedOutMenuContentState extends State<LoggedOutMenuContent> {
  bool _isLoading = false;

  Future<void> _loginWithKakao() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService().loginWithKakao();

      if (user != null) {
        if (!mounted) return;

        // Provider를 통한 상태 업데이트
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        if (!mounted) return;
        Navigator.pop(context);

        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('로그인 성공')),
        );
      }
    } catch (e) {
      print('로그인 처리 중 에러: $e');
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
                onTap: _isLoading ? null : _loginWithKakao,
                child: _isLoading
                    ? const CircularProgressIndicator()
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
