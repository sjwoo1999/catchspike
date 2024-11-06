import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_status.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final String kakaoId;
  final String? profileImageUrl;
  final DateTime lastLoginAt;
  final OnboardingStatus? onboarding;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.kakaoId,
    this.profileImageUrl,
    required this.lastLoginAt,
    this.onboarding, // 생성자에 추가
  });

  // Firestore에서 데이터를 변환하는 factory constructor
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return User(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      kakaoId: data['kakaoId'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      onboarding: data['onboarding'] != null
          ? OnboardingStatus.fromJson(
              data['onboarding'] as Map<String, dynamic>)
          : null, // fromFirestore에 추가
    );
  }

  // 날짜 필드 타입 변환 함수
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      throw Exception('Unsupported date format');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'kakaoId': kakaoId,
      'profileImageUrl': profileImageUrl,
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'onboarding': onboarding?.toJson(), // toFirestore에 추가
    };
  }

  // 객체 복사를 위한 copyWith 메서드 추가
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? kakaoId,
    String? profileImageUrl,
    DateTime? lastLoginAt,
    OnboardingStatus? onboarding,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      kakaoId: kakaoId ?? this.kakaoId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      onboarding: onboarding ?? this.onboarding,
    );
  }
}
