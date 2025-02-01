// lib/models/meal_record.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'analysis_result.dart';

class MealRecord {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime timestamp;
  final String mealType;
  final AnalysisResult? analysisResult;
  final String status; // e.g., 'pending_analysis', 'analysis_complete', 'error'
  final DateTime? analyzedAt;
  final String? error;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MealRecord({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
    required this.mealType,
    this.analysisResult,
    this.status = 'pending_analysis',
    this.analyzedAt,
    this.error,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore 문서 -> MealRecord 객체
  factory MealRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealRecord(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      mealType: data['mealType'] as String,
      analysisResult: data['analysisResult'] != null
          ? AnalysisResult.fromJson(
              data['analysisResult'] as Map<String, dynamic>,
            )
          : null,
      status: data['status'] as String? ?? 'pending_analysis',
      analyzedAt: data['analyzedAt'] != null
          ? (data['analyzedAt'] as Timestamp).toDate()
          : null,
      error: data['error'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // MealRecord -> Firestore 문서
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'mealType': mealType,
      'analysisResult': analysisResult?.toJson(),
      'status': status,
      'analyzedAt': analyzedAt != null ? Timestamp.fromDate(analyzedAt!) : null,
      'error': error,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // 객체 복사본 생성 (부분 필드 변경)
  MealRecord copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    DateTime? timestamp,
    String? mealType,
    AnalysisResult? analysisResult,
    String? status,
    DateTime? analyzedAt,
    String? error,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      analysisResult: analysisResult ?? this.analysisResult,
      status: status ?? this.status,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
