// lib/services/auth_service.dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<User?> loginWithKakao() async {
    try {
      print('카카오 로그인 시작');
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token;

      if (isInstalled) {
        print('카카오톡으로 로그인 시도');
        token = await UserApi.instance.loginWithKakaoTalk();

        // 사용자 정보 가져오기
        User user = await UserApi.instance.me();

        // 이메일 정보가 없다면 추가 동의 요청
        if (user.kakaoAccount?.email == null) {
          print('이메일 정보 추가 동의 요청');
          await UserApi.instance.loginWithNewScopes(['account_email']);
          // 사용자 정보 다시 조회
          user = await UserApi.instance.me();
        }

        return user;
      } else {
        print('카카오 계정으로 로그인 시도');
        // 웹 로그인은 한 번에 모든 동의 항목 요청
        token = await UserApi.instance.loginWithKakaoAccount();

        // 사용자 정보 조회
        User user = await UserApi.instance.me();

        // 이메일 정보가 없다면 추가 동의 요청
        if (user.kakaoAccount?.email == null) {
          print('이메일 정보 추가 동의 요청');
          await UserApi.instance.loginWithNewScopes(['account_email']);
          // 사용자 정보 다시 조회
          user = await UserApi.instance.me();
        }

        print('토큰 발급 성공: ${token.accessToken}');
        print('사용자 정보 가져오기 성공: ${user.id}');
        print('이메일: ${user.kakaoAccount?.email}');
        print('닉네임: ${user.kakaoAccount?.profile?.nickname}');
        print('프로필 이미지: ${user.kakaoAccount?.profile?.profileImageUrl}');

        return user;
      }
    } catch (e) {
      print('로그인 실패 상세 에러: $e');
      return null;
    }
  }
}
