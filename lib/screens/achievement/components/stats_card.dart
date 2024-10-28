// lib/screens/achievements/components/stats_card.dart
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int totalMeals;
  final int averageScore;
  final int perfectDays;

  const StatsCard({
    super.key,
    required this.totalMeals,
    required this.averageScore,
    required this.perfectDays,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '📊 나의 통계',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('기록한 식사', totalMeals.toString()),
                _buildStat('평균 점수', '$averageScore점'),
                _buildStat('완벽한 날', '$perfectDays일'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
