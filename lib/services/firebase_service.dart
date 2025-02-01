import 'dart:io';
import 'dart:convert'; // Base64 변환을 위한 import 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/meal_record.dart';
import '../models/users.dart';
import '../models/onboarding_status.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import '../models/analysis_result.dart';
import 'package:image/image.dart' as img;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // User 관련 메서드들
  Future<User?> getCurrentUser() async {
    try {
      final userAuth = _auth.currentUser;
      if (userAuth == null) return null;

      final userDoc =
          await _firestore.collection('users').doc(userAuth.uid).get();
      if (!userDoc.exists) {
        Logger.log('사용자 문서가 존재하지 않음: ${userAuth.uid}');
        return null;
      }

      return User.fromFirestore(userDoc);
    } catch (e) {
      Logger.log('현재 사용자 조회 실패: $e');
      rethrow;
    }
  }

  Future<void> saveUser(User user) async {
    if (_auth.currentUser?.uid != user.id) {
      throw Exception('FirebaseAuth UID와 User ID가 일치하지 않습니다.');
    }

    await _firestore
        .collection('users')
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
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
          'completedAt': Timestamp.fromDate(completedAt),
        },
      });
      Logger.log('사용자 온보딩 상태 업데이트 성공: $userId');
    } catch (e) {
      Logger.log('사용자 온보딩 상태 업데이트 실패: $e');
      rethrow;
    }
  }

  // MealRecord 관련 메서드들
  Future<MealRecord> createMealRecord({
    required String userId,
    required String imageUrl,
    required String mealType,
    required DateTime timestamp,
  }) async {
    try {
      // 1. 문서 참조 생성
      final docRef =
          _firestore.collection('users').doc(userId).collection('meals').doc();
      final now = DateTime.now();

      // 2. MealRecord 객체 생성
      final record = MealRecord(
        id: docRef.id,
        userId: userId,
        imageUrl: imageUrl,
        timestamp: timestamp,
        mealType: mealType,
        analysisResult: null,
        status: 'pending_analysis',
        createdAt: now,
        updatedAt: now,
      );

      // 3. 데이터 저장
      await docRef.set(record.toJson());

      Logger.log('식사 기록 문서 생성 성공: ${docRef.id}');
      return record;
    } catch (e) {
      Logger.log('식사 기록 생성 실패: $e');
      rethrow;
    }
  }

  Future<MealRecord?> getMealRecord(String userId, String recordId) async {
    try {
      Logger.log('식사 기록 문서 조회 시작: $recordId');

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(recordId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final record = MealRecord.fromFirestore(docSnapshot);
        Logger.log('식사 기록 조회 성공: ${record.toString()}');
        return record;
      } else {
        Logger.log('식사 기록 문서를 찾을 수 없음: $recordId');
        return null;
      }
    } catch (e) {
      Logger.log('식사 기록 조회 실패: $e');
      rethrow;
    }
  }

  Future<void> updateMealRecordStatus(
    String userId,
    String recordId, {
    required String status,
    String? error,
    AnalysisResult? analysisResult,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(recordId);

      // 업데이트할 데이터 준비
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (error != null) {
        updates['error'] = error;
      }

      if (analysisResult != null) {
        updates['analysisResult'] = analysisResult.toJson();
        updates['analyzedAt'] = FieldValue.serverTimestamp();
      }

      // 데이터 업데이트
      await docRef.update(updates);

      Logger.log('식사 기록 상태 업데이트 성공: $recordId, 상태: $status');
    } catch (e) {
      Logger.log('식사 기록 상태 업데이트 실패: $e');
      rethrow;
    }
  }

  Future<String> uploadMealImage(File imageFile, String userId) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 올바른 형식
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg'; // 숫자로 시작

      final ref = _storage
          .ref()
          .child('meal_images')
          .child(userId)
          .child(dateStr)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      final uploadTask = await ref.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      Logger.log('이미지 업로드 성공: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.log('이미지 업로드 실패: $e');
      rethrow;
    }
  }

  Future<String> getBase64ImageWithReducedSize(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final bytes = await ref.getData();

      if (bytes == null) {
        throw Exception('이미지 데이터를 가져올 수 없습니다: $imageUrl');
      }

      // 이미지 압축 및 해상도 축소
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception('이미지를 디코딩할 수 없습니다.');
      }

      final resizedImage = img.copyResize(originalImage, width: 300);
      final jpegImage = img.encodeJpg(resizedImage, quality: 70);

      final base64Image = base64Encode(jpegImage);
      Logger.log('이미지를 Base64 형식으로 변환 성공');
      return base64Image;
    } catch (e) {
      Logger.log('이미지 Base64 변환 실패: $e');
      rethrow;
    }
  }

  Stream<MealRecord> watchMealRecord(String userId, String recordId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(recordId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.data() == null) {
        throw Exception('Record not found or has been deleted');
      }
      return MealRecord.fromFirestore(snapshot);
    });
  }

  Future<void> saveAnalysisResult(
    String userId,
    String recordId,
    AnalysisResult analysisResult,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(recordId);

      final updates = {
        'analysisResult': analysisResult.toJson(),
        'status': 'analysis_saved',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(updates);

      Logger.log('분석 결과 저장 성공: $recordId');
    } catch (e) {
      Logger.log('분석 결과 저장 실패: $e');
      rethrow;
    }
  }
}
