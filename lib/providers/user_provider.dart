import 'package:flutter/foundation.dart';
import '../models/users.dart';
import '../models/onboarding_status.dart';
import '../services/firebase_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  User? get user => _user;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void setUser(User? user) {
    if (_user?.id != user?.id) {
      _user = user;
      notifyListeners();
    }
  }

  Future<void> initializeUser() async {
    if (_isLoading) return;

    try {
      setLoading(true);
      final currentUser = await _firebaseService.getCurrentUser();

      if (currentUser != null && _user?.id != currentUser.id) {
        _user = currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('사용자 초기화 오류: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firebaseService.saveUser(user);
      setUser(user);
    } catch (e) {
      debugPrint('사용자 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }

  bool get isAuthenticated => _user != null;

  bool get hasCompletedOnboarding {
    return _user?.onboarding?.isCompleted ?? false;
  }

  Future<void> updateOnboardingStatus({
    required bool isCompleted,
  }) async {
    if (_user == null) return;

    try {
      await _firebaseService.updateUserOnboardingStatus(
        userId: _user!.id,
        isCompleted: isCompleted,
        completedAt: DateTime.now(),
      );

      _user = _user!.copyWith(
        onboarding: OnboardingStatus(
          isCompleted: isCompleted,
          completedAt: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('온보딩 상태 업데이트 오류: $e');
      rethrow;
    }
  }
}
