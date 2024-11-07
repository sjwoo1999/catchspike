import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/meal_record.dart';
import '../../services/firebase_service.dart';
import '../../utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class MealAnalysisScreen extends StatefulWidget {
  final MealRecord mealRecord;
  final String userId;

  const MealAnalysisScreen({
    Key? key,
    required this.mealRecord,
    required this.userId,
  }) : super(key: key);

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String? _error;
  MealRecord? _currentRecord;

  @override
  void initState() {
    super.initState();
    _loadAnalysisResult();
  }

  Future<void> _loadAnalysisResult() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _firebaseService
          .watchMealRecord(widget.userId, widget.mealRecord.id)
          .listen(
        (updatedRecord) {
          Logger.log('분석 결과 업데이트: ${updatedRecord.toString()}');
          if (mounted) {
            setState(() {
              _currentRecord = updatedRecord;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          Logger.log('분석 결과 스트림 에러: $error');
          if (mounted) {
            setState(() {
              _error = '데이터 로드 중 오류가 발생했습니다';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      Logger.log('분석 결과 로드 실패: $e');
      if (mounted) {
        setState(() {
          _error = '분석 결과를 불러오는 중 오류가 발생했습니다';
          _isLoading = false;
        });
      }
    }
  }

  void _retryAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _firebaseService.updateMealRecordStatus(
        widget.userId,
        widget.mealRecord.id,
        status: 'pending',
      );

      _loadAnalysisResult();
    } catch (e) {
      Logger.log('재분석 시도 실패: $e');
      if (mounted) {
        setState(() {
          _error = '재분석 시도 중 오류가 발생했습니다';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재분석 시도 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareResult() {
    if (_currentRecord == null) return;

    final analysisResult = _currentRecord?.analysisResult;
    if (analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 분석 결과가 없습니다')),
      );
      return;
    }

    final dateFormatter = DateFormat('yyyy/MM/dd');
    final formattedDate = dateFormatter.format(_currentRecord!.timestamp);

    final foodItems = analysisResult['foodItems'] as List<dynamic>? ?? [];
    final foodList = foodItems.map((item) => item['name']).join(', ');

    final shareText = '''
📊 식사 분석 결과

📅 날짜: $formattedDate
🕒 시간: ${_getMealTypeText(_currentRecord!.mealType)}

🍽️ 음식: $foodList

#CatchSpike #식사기록 #건강관리
''';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '식사 분석 결과',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_currentRecord?.status == 'completed')
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareResult,
            ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('분석 결과를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_currentRecord == null) {
      return const Center(
        child: Text('데이터를 찾을 수 없습니다'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _currentRecord!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('이미지를 불러올 수 없습니다'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getMealTypeText(_currentRecord!.mealType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy/MM/dd')
                          .format(_currentRecord!.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_currentRecord!.status == 'completed')
                  _buildAnalysisResult()
                else if (_currentRecord!.status == 'analyzing')
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('이미지 분석 중...'),
                      ],
                    ),
                  )
                else if (_currentRecord!.status == 'failed')
                  Center(
                    child: Column(
                      children: [
                        const Text('분석에 실패했습니다'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _retryAnalysis,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final analysisResult = _currentRecord?.analysisResult;
    if (analysisResult == null) {
      return const Center(
        child: Text('분석 결과가 없습니다'),
      );
    }

    final nutrients =
        analysisResult['nutrition']?['nutrients'] as Map<String, double>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '분석 결과',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '영양 성분',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: nutrients.entries.map((entry) {
                return PieChartSectionData(
                  title: '${entry.key}: ${entry.value}g',
                  value: entry.value,
                  radius: 60,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getMealTypeText(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '아침';
      case 'lunch':
        return '점심';
      case 'dinner':
        return '저녁';
      case 'snack':
        return '간식';
      default:
        return mealType;
    }
  }
}
