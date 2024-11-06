// meal_record.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MealRecord {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime timestamp;
  final String mealType;
  final Map<String, dynamic> analysisResult;
  final String status;
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
    required this.analysisResult,
    this.status = 'pending_analysis',
    this.analyzedAt,
    this.error,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore 문서에서 MealRecord 객체 생성
  factory MealRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealRecord(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      mealType: data['mealType'] as String,
      analysisResult: data['analysisResult'] as Map<String, dynamic>? ?? {},
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

  // MealRecord 객체를 Firestore 문서 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'mealType': mealType,
      'analysisResult': analysisResult,
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

  // 객체 복사본 생성 및 특정 필드 업데이트
  MealRecord copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    DateTime? timestamp,
    String? mealType,
    Map<String, dynamic>? analysisResult,
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

  // 상태 검사 메서드들
  bool get isAnalyzing => status == 'analyzing';
  bool get isAnalyzed => status == 'analyzed';
  bool get hasError => status == 'analysis_failed';
  bool get isPending => status == 'pending_analysis';

  // 분석 결과 관련 getter 메서드들
  List<String> get foodItems {
    try {
      final analysis = analysisResult['analysis'] as Map<String, dynamic>?;
      return (analysis?['foodList'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [];
    } catch (e) {
      return [];
    }
  }

  double get totalCalories {
    try {
      final analysis = analysisResult['analysis'] as Map<String, dynamic>?;
      return (analysis?['totalCalories'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, double> get nutrients {
    try {
      final analysis = analysisResult['analysis'] as Map<String, dynamic>?;
      final nutrients = analysis?['nutrients'] as Map<String, dynamic>?;
      return {
        'carbs': (nutrients?['carbs'] as num?)?.toDouble() ?? 0.0,
        'protein': (nutrients?['protein'] as num?)?.toDouble() ?? 0.0,
        'fat': (nutrients?['fat'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return {
        'carbs': 0.0,
        'protein': 0.0,
        'fat': 0.0,
      };
    }
  }

  List<String> get healthSuggestions {
    try {
      final analysis = analysisResult['analysis'] as Map<String, dynamic>?;
      return (analysis?['suggestions'] as List<dynamic>?)
              ?.map((suggestion) => suggestion.toString())
              .toList() ??
          [];
    } catch (e) {
      return [];
    }
  }

  // toString 메서드 오버라이드
  @override
  String toString() {
    return 'MealRecord(id: $id, userId: $userId, mealType: $mealType, '
        'status: $status, timestamp: $timestamp)';
  }

  // equals 메서드 오버라이드
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealRecord &&
        other.id == id &&
        other.userId == userId &&
        other.imageUrl == imageUrl &&
        other.timestamp == timestamp &&
        other.mealType == mealType &&
        other.status == status;
  }

  // hashCode 메서드 오버라이드
  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      imageUrl,
      timestamp,
      mealType,
      status,
    );
  }
}
