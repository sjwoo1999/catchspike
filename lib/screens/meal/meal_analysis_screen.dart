// lib/screens/meal/meal_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:catchspike/models/meal_record.dart';
import 'package:catchspike/utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:catchspike/widgets/loading_indicator.dart';
import 'components/analysis_status.dart';

class MealAnalysisScreen extends StatelessWidget {
  final MealRecord mealRecord;

  const MealAnalysisScreen({
    Key? key,
    required this.mealRecord,
  }) : super(key: key);

  String _getMealTypeText(String type) {
    switch (type) {
      case 'breakfast':
        return '아침';
      case 'lunch':
        return '점심';
      case 'dinner':
        return '저녁';
      case 'snack':
        return '간식';
      default:
        return '식사';
    }
  }

  Future<void> _shareMealAnalysis(BuildContext context) async {
    try {
      final foods = mealRecord.analysisResult?['foods'] as List<dynamic>?;
      final nutrition = mealRecord.analysisResult?['nutrition'];

      final text = '''
${_formatDateTime(mealRecord.timestamp)}
${_getMealTypeText(mealRecord.mealType)} 식사 분석 결과

총 칼로리: ${nutrition?['calories']} kcal

분석된 음식:
${foods?.map((food) => '• ${food['name']} (${food['calories']}kcal)').join('\n')}

영양 정보:
탄수화물: ${nutrition?['carbs']}g
단백질: ${nutrition?['protein']}g
지방: ${nutrition?['fat']}g

${mealRecord.analysisResult?['recommendations'] ?? ''}
      ''';

      await Share.share(text);
    } catch (e) {
      Logger.log('식사 분석 공유 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유하기에 실패했습니다.')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${_getMealTypeText(mealRecord.mealType)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식사 분석 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareMealAnalysis(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(context),
              _buildAnalysisSection(),
              _buildRecommendationSection(),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          mealRecord.imageUrl,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            Logger.log('이미지 로드 실패: $error');
            return Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, size: 50),
            );
          },
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMealTypeText(mealRecord.mealType),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection() {
    final nutrition = mealRecord.analysisResult?['nutrition'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '영양 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNutritionRow(
                      '칼로리', '${nutrition?['calories'] ?? 0} kcal'),
                  _buildNutritionRow('탄수화물', '${nutrition?['carbs'] ?? 0}g'),
                  _buildNutritionRow('단백질', '${nutrition?['protein'] ?? 0}g'),
                  _buildNutritionRow('지방', '${nutrition?['fat'] ?? 0}g'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFoodList(),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    final foods = mealRecord.analysisResult?['foods'] as List<dynamic>?;
    if (foods == null || foods.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석된 음식',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...foods.map((food) => _buildFoodItem(food)),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              food['name'] as String,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '${food['calories']}kcal',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    final recommendations = mealRecord.analysisResult?['recommendations'];
    if (recommendations == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '영양 추천사항',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                recommendations.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _shareMealAnalysis(context),
              icon: const Icon(Icons.share),
              label: const Text('공유하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('새로운 분석'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
