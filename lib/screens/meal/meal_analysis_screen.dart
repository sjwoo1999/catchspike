// lib/screens/meal_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/meal_record.dart';
import '../../models/analysis_result.dart';

class MealAnalysisScreen extends StatefulWidget {
  final String mealRecordId;

  const MealAnalysisScreen({
    Key? key,
    required this.mealRecordId,
  }) : super(key: key);

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  MealRecord? _mealRecord;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMealRecord();
  }

  Future<void> _loadMealRecord() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('meal_records')
          .doc(widget.mealRecordId)
          .get();

      if (!doc.exists) {
        throw Exception('해당 MealRecord가 존재하지 않습니다.');
      }
      final record = MealRecord.fromFirestore(doc);

      if (mounted) {
        setState(() {
          _mealRecord = record;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('분석 결과 조회')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('분석 결과 조회')),
        body: Center(child: Text(_errorMessage)),
      );
    }

    if (_mealRecord == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('분석 결과 조회')),
        body: const Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }

    final record = _mealRecord!;
    final analysis = record.analysisResult; // AnalysisResult?
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('MealRecord ID: ${record.id}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (record.imageUrl.isNotEmpty)
              Image.network(record.imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text('상태: ${record.status}', style: const TextStyle(fontSize: 16)),
            if (record.error != null)
              Text('에러: ${record.error}',
                  style: const TextStyle(color: Colors.red)),
            const Divider(height: 32),
            if (analysis != null) ...[
              _buildAnalysisDetail(analysis),
            ] else ...[
              const Text('아직 분석 결과가 없습니다.'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisDetail(AnalysisResult analysis) {
    // detectedFoods, nutrition, comment, etc.
    final foods = analysis.detectedFoods;
    final nutrition = analysis.nutritionAnalysis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('분석된 음식 목록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...foods.map((food) => Text(
            '- ${food.name} (conf: ${food.confidence}, giIndex: ${food.giIndex})')),
        const SizedBox(height: 16),
        Text('영양 정보 (GI: ${nutrition.GI}, cal: ${nutrition.calories})',
            style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Comment: ${analysis.comment}',
            style: const TextStyle(fontSize: 16)),
        Text('Health Score: ${analysis.overallHealthScore}',
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
