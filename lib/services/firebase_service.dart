// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../models/user.dart' as app_user;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Kakao 사용자 정보를 Firebase에 저장
  Future<void> saveUserToFirebase(User kakaoUser) async {
    try {
      // Kakao 사용자 정보로 커스텀 토큰 생성 (백엔드에서 처리해야 함)
      // 여기서는 예시로 직접 로그인하는 방식을 보여줍니다
      final userCredential = await _auth.signInAnonymously();
      final uid = userCredential.user!.uid;

      // Firestore에 사용자 정보 저장
      final userData = app_user.User(
        id: uid,
        name: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
        email: kakaoUser.kakaoAccount?.email ?? '',
      );

      await _firestore.collection('users').doc(uid).set(
            userData.toJson(),
            SetOptions(merge: true),
          );

      print('Firebase에 사용자 정보 저장 완료: $uid');
    } catch (e) {
      print('Firebase 사용자 정보 저장 실패: $e');
      rethrow;
    }
  }

  // Firebase에서 사용자 정보 조회
  Future<app_user.User?> getUserFromFirebase(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Firebase 사용자 정보 조회 실패: $e');
      return null;
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserInFirebase(app_user.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      print('Firebase 사용자 정보 업데이트 완료');
    } catch (e) {
      print('Firebase 사용자 정보 업데이트 실패: $e');
      rethrow;
    }
  }
}
