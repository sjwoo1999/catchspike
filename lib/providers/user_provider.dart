// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User newUser) {
    print('UserProvider setUser 호출됨');
    print('이전 사용자: ${_user?.id}');
    print('새로운 사용자: ${newUser.id}');

    _user = newUser;
    notifyListeners();

    print('UserProvider setUser 완료');
    print('현재 사용자: ${_user?.id}');
  }

  void clearUser() {
    print('UserProvider clearUser 호출됨');
    _user = null;
    notifyListeners();
    print('UserProvider clearUser 완료');
  }
}
