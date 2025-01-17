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
    // DateTime의 weekday는 1(월요일)부터 7(일요일)을 발행
    return days[now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트'),
        backgroundColor: const Color(0xFFE30547),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                meals: const [
                  Meal(
                    time: '아침',
                    menu: '샐러드와 닭가슴살',
                    calories: 400,
                    healthScore: 85,
                    imageUrl: 'assets/images/breakfast_salad.jpg',
                  ),
                  Meal(
                    time: '점심',
                    menu: '현미밥과 불고기',
                    calories: 650,
                    healthScore: 75,
                    imageUrl: 'assets/images/lunch_bulgogi.jpg',
                  ),
                  Meal(
                    time: '저녁',
                    menu: '두부김치와 잡곡밥',
                    calories: 450,
                    healthScore: 80,
                    imageUrl: 'assets/images/dinner_tofu.jpg',
                  ),
                ],
                onTap: () => _showMealHistory(context),
              ),
              const SizedBox(height: 20),

              // 건강 인사이트
              HealthInsightCard(
                insights: const [
                  '오늘은 목표 칼로리의 60%를 섭취했어요',
                  '점심 식사 시간이 평소보다 10분 더 길었어요',
                  '단백질 섭취가 부족해요',
                ],
                onTap: () => _showHealthInsights(context),
              ),
              const SizedBox(height: 20),

              // 식사 기록 더보기 버튼 디자인 변경
              ElevatedButton(
                onPressed: () => _showMealHistory(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.restaurant_menu),
                    SizedBox(width: 8),
                    Text(
                      '식사 기록 더보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
