// lib/models/analysis_result.dart

import 'food_item.dart';

class AnalysisResult {
  final List<FoodItem> detectedFoods;
  final NutritionAnalysis nutritionAnalysis;
  final String comment;
  final int overallHealthScore;
  final String scoreBasis;
  final AnalysisMetadata metadata;

  const AnalysisResult({
    required this.detectedFoods,
    required this.nutritionAnalysis,
    required this.comment,
    required this.overallHealthScore,
    required this.scoreBasis,
    required this.metadata,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      detectedFoods: (json['foods'] as List)
          .map((food) => FoodItem.fromJson(food))
          .toList(),
      nutritionAnalysis: NutritionAnalysis.fromJson(json['nutrition']),
      comment: json['comment'] ?? "",
      overallHealthScore: json['overall_health_score'] ?? 0,
      scoreBasis: json['score_basis'] ?? "",
      metadata: AnalysisMetadata.fromJson(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'foods': detectedFoods.map((food) => food.toJson()).toList(),
        'nutrition': nutritionAnalysis.toJson(),
        'comment': comment,
        'overall_health_score': overallHealthScore,
        'score_basis': scoreBasis,
        'metadata': metadata.toJson(),
      };
}

class NutritionAnalysis {
  final double glycemicIndex;
  final double calories;
  final double GI;
  final double estimatedGrams;

  const NutritionAnalysis({
    required this.glycemicIndex,
    required this.calories,
    required this.GI,
    required this.estimatedGrams,
  });

  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) {
    return NutritionAnalysis(
      glycemicIndex: (json['glycemic_index'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      GI: (json['GI'] as num?)?.toDouble() ?? 0.0,
      estimatedGrams: (json['estimated_grams'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'glycemic_index': glycemicIndex,
        'calories': calories,
        'GI': GI,
        'estimated_grams': estimatedGrams,
      };
}

class AnalysisMetadata {
  final DateTime analyzedAt;
  final String mealType;
  final String? imageUrl;
  final String? modelVersion;

  const AnalysisMetadata({
    required this.analyzedAt,
    required this.mealType,
    this.imageUrl,
    this.modelVersion,
  });

  factory AnalysisMetadata.fromJson(Map<String, dynamic> json) {
    return AnalysisMetadata(
      analyzedAt: DateTime.parse(json['analyzedAt']),
      mealType: json['mealType'],
      imageUrl: json['imageUrl'],
      modelVersion: json['modelVersion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'analyzedAt': analyzedAt.toIso8601String(),
        'mealType': mealType,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (modelVersion != null) 'modelVersion': modelVersion,
      };
}
