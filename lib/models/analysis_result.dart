// lib/models/analysis_result.dart

import 'food_item.dart';

class AnalysisResult {
  final List<FoodItem> detectedFoods;
  final NutritionAnalysis nutritionAnalysis;
  final List<String> recommendations;
  final AnalysisMetadata metadata;

  const AnalysisResult({
    required this.detectedFoods,
    required this.nutritionAnalysis,
    required this.recommendations,
    required this.metadata,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      detectedFoods: (json['foods']['detected'] as List)
          .map((food) => FoodItem.fromJson(food))
          .toList(),
      nutritionAnalysis: NutritionAnalysis.fromJson(json['nutrition']),
      recommendations: List<String>.from(json['recommendations']['tips']),
      metadata: AnalysisMetadata.fromJson(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'foods': {
          'detected': detectedFoods.map((food) => food.toJson()).toList(),
        },
        'nutrition': nutritionAnalysis.toJson(),
        'recommendations': {
          'tips': recommendations,
        },
        'metadata': metadata.toJson(),
      };
}

class NutritionAnalysis {
  final Map<String, double> giIndices;
  final List<String> eatingOrder;
  final Map<String, double> nutrients;
  final double totalCalories;

  const NutritionAnalysis({
    required this.giIndices,
    required this.eatingOrder,
    required this.nutrients,
    required this.totalCalories,
  });

  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) {
    return NutritionAnalysis(
      giIndices: Map<String, double>.from(json['giIndices']),
      eatingOrder: List<String>.from(json['eatingOrder']),
      nutrients: Map<String, double>.from(json['nutrients']),
      totalCalories: (json['totalCalories'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'giIndices': giIndices,
        'eatingOrder': eatingOrder,
        'nutrients': nutrients,
        'totalCalories': totalCalories,
      };
}

class AnalysisMetadata {
  final DateTime analyzedAt;
  final String mealType;
  final String imageUrl;
  final String? modelVersion;

  const AnalysisMetadata({
    required this.analyzedAt,
    required this.mealType,
    required this.imageUrl,
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
        'imageUrl': imageUrl,
        if (modelVersion != null) 'modelVersion': modelVersion,
      };
}
