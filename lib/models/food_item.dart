// lib/models/food_item.dart

class FoodItem {
  final String name;
  final double confidence;
  final double? giIndex;
  final Map<String, double>? nutrients;

  const FoodItem({
    required this.name,
    required this.confidence,
    this.giIndex,
    this.nutrients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      confidence: (json['value'] as num).toDouble(),
      giIndex:
          json['giIndex'] != null ? (json['giIndex'] as num).toDouble() : null,
      nutrients: json['nutrients'] != null
          ? Map<String, double>.from(json['nutrients'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': confidence,
        if (giIndex != null) 'giIndex': giIndex,
        if (nutrients != null) 'nutrients': nutrients,
      };

  @override
  String toString() => 'FoodItem(name: $name, confidence: $confidence)';
}
