// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/users.dart';
import '../services/firebase_service.dart';
import '../utils/logger.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> initializeUser() async {
    try {
      setLoading(true);
      final currentUser = await _firebaseService.getCurrentUser();

      if (currentUser != null) {
        _user = currentUser;
        Logger.log('사용자 정보 초기화 성공: ${currentUser.id}');
      } else {
        Logger.log('사용자 정보 없음');
      }
      notifyListeners();
    } catch (e) {
      Logger.log('사용자 정보 초기화 실패: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> setUser(User user) async {
    try {
      setLoading(true);
      await _firebaseService.saveUser(user);
      _user = user;
      Logger.log('사용자 정보 업데이트 성공: ${user.id}');
      notifyListeners();
    } catch (e) {
      Logger.log('사용자 정보 업데이트 실패: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  Future<void> clearUser() async {
    try {
      _user = null;
      Logger.log('사용자 정보 초기화 완료');
      notifyListeners();
    } catch (e) {
      Logger.log('사용자 정보 초기화 실패: $e');
      rethrow;
    }
  }
}
