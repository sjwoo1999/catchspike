// lib/models/user_details.dart

class UserDetails {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  UserDetails({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
