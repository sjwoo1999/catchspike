import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final String kakaoId;
  final String? profileImageUrl;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.kakaoId,
    this.profileImageUrl,
    required this.lastLoginAt,
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
      'lastLoginAt':
          Timestamp.fromDate(lastLoginAt), // Firestore에 저장할 때는 Timestamp 사용
    };
  }
}
