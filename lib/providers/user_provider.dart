// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUser(User newUser) {
    print('UserProvider setUser 호출됨');
    print('이전 사용자: ${_user?.id}');
    print('새로운 사용자: ${newUser.id}');

    _user = newUser;
    notifyListeners();

    print('UserProvider setUser 완료');
    print('현재 사용자: ${_user?.id}');

    // 사용자 정보 로그
    print('사용자 닉네임: ${_user?.kakaoAccount?.profile?.nickname}');
    print('사용자 이메일: ${_user?.kakaoAccount?.email}');
    print('프로필 이미지: ${_user?.kakaoAccount?.profile?.profileImageUrl}');
  }

  void clearUser() {
    print('UserProvider clearUser 호출됨');
    _user = null;
    notifyListeners();
    print('UserProvider clearUser 완료');
  }

  // 사용자 정보 초기화 (앱 시작시 호출)
  Future<void> initializeUser() async {
    _setLoading(true);
    try {
      if (await AuthApi.instance.hasToken()) {
        try {
          // 기존 토큰으로 사용자 정보 가져오기
          User user = await UserApi.instance.me();
          setUser(user);
        } catch (e) {
          print('토큰은 있지만 사용자 정보 가져오기 실패: $e');
          clearUser();
        }
      }
    } catch (e) {
      print('사용자 초기화 중 에러: $e');
    } finally {
      _setLoading(false);
    }
  }
}
