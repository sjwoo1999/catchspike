// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../providers/user_provider.dart';
import '../utils/global_keys.dart'; // GlobalKey import

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final bool isLoggedIn = userProvider.user != null;
          print("CustomDrawer: isLoggedIn = $isLoggedIn"); // 디버그 로그
          return isLoggedIn ? LoggedInMenuContent() : LoggedOutMenuContent();
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
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final User? user = userProvider.user;

    final String userName = user?.kakaoAccount?.profile?.nickname ?? '사용자 이름';
    final String userEmail = user?.kakaoAccount?.email ?? 'user@example.com';
    final String profileImageUrl =
        user?.kakaoAccount?.profile?.profileImageUrl ??
            'assets/images/default_profile.png';

    // 로그아웃 함수
    Future<void> _logout() async {
      try {
        await UserApi.instance.logout();
        userProvider.clearUser();

        print('로그아웃 성공');
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('로그아웃 성공')),
        );
      } catch (e) {
        print('로그아웃 실패 $e');
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }

    return ListView(
      children: [
        // 프로필 영역
        Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent, // 배경색을 투명하게 설정
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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
            Navigator.pop(context); // 드로어 닫기
            // 실제 페이지로 이동하는 코드 추가
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('마이페이지'),
          onTap: () {
            Navigator.pop(context); // 드로어 닫기
            // 실제 페이지로 이동하는 코드 추가
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: () async {
            Navigator.pop(context); // 드로어 닫기
            await _logout();
          },
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
  @override
  Widget build(BuildContext context) {
    // 로그인 함수
    Future<void> _loginWithKakao() async {
      try {
        bool isInstalled = await isKakaoTalkInstalled();
        OAuthToken token;

        if (isInstalled) {
          token = await UserApi.instance.loginWithKakaoTalk();
        } else {
          token = await UserApi.instance.loginWithKakaoAccount();
        }

        User user = await UserApi.instance.me();
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        print('로그인 성공 ${user.kakaoAccount?.email}');
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('로그인 성공')),
        );
      } catch (e) {
        print('로그인 실패 $e');
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }

    return ListView(
      children: [
        // 프로필 영역
        Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent, // 배경색을 투명하게 설정
                backgroundImage:
                    AssetImage('assets/images/default_profile.png'),
              ),
              const SizedBox(height: 16),
              const Text(
                '로그인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
              // 이미지 버튼
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context); // 드로어 닫기
                  await _loginWithKakao();
                },
                child: Image.asset(
                  'assets/images/kakao_login_medium_narrow.png',
                  fit: BoxFit.contain,
                  width: 200, // 필요한 경우 크기 조정
                ),
              ),
            ],
          ),
        ),
        // 필요 시 다른 메뉴 항목을 추가할 수 있습니다.
      ],
    );
  }
}
