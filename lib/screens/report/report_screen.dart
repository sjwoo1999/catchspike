import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'components/meal_history.dart';
import 'components/health_insights.dart';
import 'components/calorie_summary.dart';
import 'screens/calorie_details_screen.dart';
import 'screens/meal_history_screen.dart';
import 'screens/health_insights_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('M월 d일');
    return formatter.format(now);
  }

  String _getKoreanWeekDay() {
    final now = DateTime.now();
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    // DateTime의 weekday는 1(월요일)부터 7(일요일)을 반환
    return days[now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 요약
            Text(
              '${_getFormattedDate()} ${_getKoreanWeekDay()}의 기록',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),

            // 칼로리 요약 카드
            CalorieSummaryCard(
              currentCalories: 1500,
              targetCalories: 2500,
              onTap: () => _showCalorieDetails(context),
            ),
            const SizedBox(height: 20),

            // 오늘의 식사 기록
            MealHistoryCard(
              meals: [
                Meal(
                  time: '아침',
                  menu: '샐러드와 닭가슴살',
                  calories: 400,
                  healthScore: 85,
                ),
                Meal(
                  time: '점심',
                  menu: '현미밥과 불고기',
                  calories: 650,
                  healthScore: 75,
                ),
              ],
              onTap: () => _showMealHistory(context),
            ),
            const SizedBox(height: 20),

            // 건강 인사이트
            HealthInsightCard(
              insights: [
                '오늘은 목표 칼로리의 60%를 섭취했어요',
                '점심 식사 시간이 평소보다 10분 더 길었어요',
                '단백질 섭취가 부족해요',
              ],
              onTap: () => _showHealthInsights(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalorieDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalorieDetailsScreen(),
      ),
    );
  }

  void _showMealHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealHistoryScreen(),
      ),
    );
  }

  void _showHealthInsights(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthInsightsScreen(),
      ),
    );
  }
}
