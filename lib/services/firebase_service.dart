// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:catchspike/models/users.dart' as app_user;
import 'package:catchspike/utils/logger.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/meal_record.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUser(app_user.User user) async {
    try {
      Logger.log('사용자 정보 저장 시작: ${user.id}');
      Map<String, dynamic> userData = user.toFirestore();
      Logger.log('변환된 Firestore 데이터: $userData');

      await _firestore.collection('users').doc(user.id).set(
            userData,
            SetOptions(merge: true),
          );

      Logger.log('사용자 정보 저장 성공: ${user.id}');
    } catch (e) {
      Logger.log('사용자 정보 저장 실패: $e');
      rethrow;
    }
  }

  Future<app_user.User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        Logger.log('현재 로그인된 사용자 없음');
        return null;
      }

      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists) {
        Logger.log('사용자 문서가 Firestore에 존재하지 않음: ${firebaseUser.uid}');
        return null;
      }

      final user = app_user.User.fromFirestore(doc);
      Logger.log('현재 사용자 정보 로드 성공: ${user.id}');
      return user;
    } catch (e) {
      Logger.log('현재 사용자 정보 조회 실패: $e');
      rethrow;
    }
  }

  Future<String> uploadMealImage(File imageFile, String userId) async {
    try {
      final String date = DateTime.now().toIso8601String().split('T')[0];
      final fileName =
          'meal_images/$userId/$date/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(fileName);

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 이미지 업로드
      final uploadTask = await storageRef.putFile(imageFile, metadata);

      // URL 가져오기 및 검증
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // URL 검증
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('이미지 URL 검증 실패: ${response.statusCode}');
      }

      return downloadUrl;
    } catch (e) {
      Logger.log('이미지 업로드 실패: $e');
      rethrow;
    }
  }

  Future<void> saveMealRecord(MealRecord mealRecord) async {
    try {
      final recordData = {
        ...mealRecord.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(mealRecord.userId)
          .collection('meal_records')
          .add(recordData);

      Logger.log('식사 기록 저장 성공');
    } catch (e) {
      Logger.log('식사 기록 저장 실패: $e');
      rethrow;
    }
  }

  Future<void> updateUserOnboardingStatus({
    required String userId,
    required bool isCompleted,
    required DateTime completedAt,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'onboarding': {
          'isCompleted': isCompleted,
          'completedAt': completedAt,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.log('온보딩 상태 업데이트 성공: $userId');
    } catch (e) {
      Logger.log('온보딩 상태 업데이트 실패: $e');
      rethrow;
    }
  }
}
