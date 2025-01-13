import 'package:flutter/material.dart';

class Meal {
  final String time;
  final String menu;
  final int calories;
  final int healthScore;
  final String imageUrl;

  const Meal({
    required this.time,
    required this.menu,
    required this.calories,
    required this.healthScore,
    required this.imageUrl,
  });
}

class MealHistoryCard extends StatelessWidget {
  final List<Meal> meals;
  final VoidCallback onTap;

  const MealHistoryCard({
    super.key,
    required this.meals,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘의 식사',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...meals.map((meal) => MealItem(meal: meal)),
            ],
          ),
        ),
      ),
    );
  }
}

class MealItem extends StatelessWidget {
  final Meal meal;

  const MealItem({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              meal.time,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.menu,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${meal.calories}kcal • 건강점수 ${meal.healthScore}점',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
