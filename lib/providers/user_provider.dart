// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    print("UserProvider: setUser 호출 - 사용자: ${user.kakaoAccount?.email}");
    notifyListeners(); // 상태 변화 알림
  }

  void clearUser() {
    _user = null;
    print("UserProvider: clearUser 호출");
    notifyListeners(); // 상태 변화 알림
  }
}
