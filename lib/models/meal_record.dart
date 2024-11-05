class MealRecord {
  final String userId;
  final String imageUrl;
  final String mealType;
  final DateTime timestamp;
  final Map<String, dynamic>? analysisResult; // ChatGPT 응답 전체를 저장

  MealRecord({
    required this.userId,
    required this.imageUrl,
    required this.mealType,
    required this.timestamp,
    this.analysisResult,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'imageUrl': imageUrl,
        'mealType': mealType,
        'timestamp': timestamp.toIso8601String(),
        'analysisResult': analysisResult,
      };

  factory MealRecord.fromJson(Map<String, dynamic> json) => MealRecord(
        userId: json['userId'],
        imageUrl: json['imageUrl'],
        mealType: json['mealType'],
        timestamp: DateTime.parse(json['timestamp']),
        analysisResult: json['analysisResult'],
      );
}
