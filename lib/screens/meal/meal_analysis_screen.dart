import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:catchspike/models/meal_record.dart';
import 'package:catchspike/services/meal_analysis_service.dart';
import 'package:catchspike/utils/logger.dart';
import 'package:image/image.dart' as img;
import 'package:catchspike/widgets/loading_overlay.dart';
import 'package:path_provider/path_provider.dart';

class MealAnalysisScreen extends StatefulWidget {
  final MealRecord mealRecord;
  final Map<String, dynamic> analysisResult;

  const MealAnalysisScreen({
    Key? key,
    required this.mealRecord,
    required this.analysisResult,
  }) : super(key: key);

  @override
  State<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends State<MealAnalysisScreen> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String> _analysisStatus = ValueNotifier('');
  final ValueNotifier<Map<String, dynamic>?> _analysisResult =
      ValueNotifier(null);
  final MealAnalysisService _mealAnalysisService = MealAnalysisService();

  @override
  void initState() {
    super.initState();
    _analysisResult.value = widget.analysisResult;
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _analysisStatus.dispose();
    _analysisResult.dispose();
    super.dispose();
  }

  Future<void> _startMealAnalysis() async {
    _isLoading.value = true;
    _analysisStatus.value = '이미지 분석 중...';

    try {
      final compressedImageFile =
          await _downloadAndCompressImage(widget.mealRecord.imageUrl);
      if (compressedImageFile == null) {
        throw Exception('이미지 압축에 실패했습니다.');
      }

      // YOLOv7 분석
      _analysisStatus.value = 'YOLOv7 분석 중...';
      final yoloResult = await _mealAnalysisService
          .analyzeMealImageUsingYOLOv7(compressedImageFile);

      // OpenAI 추가 분석
      _analysisStatus.value = 'OpenAI 분석 중...';
      final base64Image =
          _mealAnalysisService.compressAndEncodeImage(compressedImageFile);
      final openAIResult = await _mealAnalysisService
          .analyzeMealImageUsingAssistant(base64Image);

      // 통합 결과 설정
      _analysisResult.value =
          _mealAnalysisService.mergeAnalysisResults(yoloResult, openAIResult);
      _analysisStatus.value = '분석 완료';
    } catch (e) {
      Logger.log('[ERROR] 분석 실패: $e');
      _analysisStatus.value = '분석 실패: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<File?> _downloadAndCompressImage(String imageUrl) async {
    try {
      // Step 1: HttpClient를 사용하여 이미지 다운로드
      final HttpClient client = HttpClient();
      final HttpClientRequest request =
          await client.getUrl(Uri.parse(imageUrl));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('이미지 다운로드 실패: 상태 코드 ${response.statusCode}');
      }

      // Step 2: 응답 바이트 수집
      final List<int> imageBytes =
          await consolidateHttpClientResponseBytes(response);
      Logger.log('[INFO] 이미지 다운로드 성공');

      // Step 3: 이미지 압축
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception("이미지 디코딩에 실패했습니다.");
      }

      // 이미지 리사이즈 및 품질 조정
      final img.Image resizedImage =
          img.copyResize(originalImage, width: originalImage.width ~/ 2);
      final List<int> compressedImage =
          img.encodeJpg(resizedImage, quality: 50);
      Logger.log('[INFO] 이미지 압축 성공');

      // Step 4: 압축된 이미지를 임시 파일로 저장
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/compressed_image.jpg';
      final compressedFile = File(filePath);
      await compressedFile.writeAsBytes(compressedImage);

      return compressedFile;
    } catch (e) {
      Logger.log('[ERROR] 이미지 압축 실패: $e');
      return null;
    }
  }

  void _resetAnalysis() {
    _isLoading.value = false;
    _analysisStatus.value = '';
    _analysisResult.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식사 분석'),
        actions: [
          if (_analysisResult.value != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnalysis,
              tooltip: '분석 다시 시작',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoading,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return _buildLoadingState();
                      } else if (_analysisResult.value != null) {
                        return _buildAnalysisResult();
                      } else {
                        return _buildInitialButton();
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_isLoading.value)
              const LoadingOverlay(
                message: '음식 분석 중...',
                useCustomIndicator: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(); // 로딩 상태는 오버레이로 대체되므로 빈 컨테이너 반환
  }

  Widget _buildInitialButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _startMealAnalysis,
          child: const Text('분석 시작'),
        ),
        const SizedBox(height: 20),
        const Text(
          '사진을 분석하여 영양 정보를 확인할 수 있습니다.',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAnalysisResult() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYOLOResult(),
            const SizedBox(height: 20),
            _buildOpenAIResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildYOLOResult() {
    final yoloAnalysis = _analysisResult.value?['yolo_analysis'] ?? {};
    final detectedFoods = yoloAnalysis['detectedFoods'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('YOLO 분석 결과',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('감지된 음식:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ...detectedFoods.map<Widget>(
            (food) => Text('- $food', style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildOpenAIResult() {
    final openAIAnalysis = _analysisResult.value?['openai_analysis'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OpenAI 분석 결과',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(openAIAnalysis['analysis'] ?? '결과를 가져오지 못했습니다.',
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
