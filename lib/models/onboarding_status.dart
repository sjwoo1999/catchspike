import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingStatus {
  final bool isCompleted;
  final DateTime? completedAt;

  OnboardingStatus({
    required this.isCompleted,
    this.completedAt,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // 편의를 위한 초기 상태 생성자
  factory OnboardingStatus.initial() {
    return OnboardingStatus(
      isCompleted: false,
      completedAt: null,
    );
  }
}
