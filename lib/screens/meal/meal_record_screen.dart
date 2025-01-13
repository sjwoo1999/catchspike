import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:catchspike/services/firebase_service.dart';
import 'package:catchspike/services/meal_analysis_service.dart';
import 'package:catchspike/models/meal_record.dart';
import 'package:catchspike/utils/logger.dart';
import 'dart:io';
import 'dart:convert'; // for base64 encoding
import '../meal/meal_analysis_screen.dart';

// Components import
import 'components/meal_image_picker.dart';
import 'components/meal_type_selector.dart';
import 'components/analysis_status.dart';

class MealRecordScreen extends StatefulWidget {
  const MealRecordScreen({super.key});

  @override
  State<MealRecordScreen> createState() => _MealRecordScreenState();
}

class _MealRecordScreenState extends State<MealRecordScreen> {
  String _selectedTime = '';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _analysisStatus = '';
  final FirebaseService _firebaseService = FirebaseService();
  final MealAnalysisService _analysisService = MealAnalysisService();

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _updateLoadingStatus({required bool isLoading, String status = ''}) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
        _analysisStatus = status;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Logger.log('이미지 선택 실패: $e');
      if (mounted) {
        _showErrorSnackBar('이미지를 불러오는데 실패했습니다.');
      }
    }
  }

  Future<String> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      Logger.log('이미지 변환 실패: $e');
      throw Exception('이미지 변환 중 오류 발생');
    }
  }

  Future<void> _analyzeMealAndSave() async {
    if (_selectedImage == null || _selectedTime.isEmpty) {
      _showErrorSnackBar('이미지와 식사 시간을 모두 선택해주세요');
      return;
    }

    _updateLoadingStatus(isLoading: true, status: '이미지 업로드 중...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      final userId = user.uid;

      // 1. 이미지 업로드
      _updateLoadingStatus(isLoading: true, status: '이미지 업로드 중...');
      final imageUrl =
          await _firebaseService.uploadMealImage(_selectedImage!, userId);

      // 2. 식사 기록 생성
      final mealRecord = await _firebaseService.createMealRecord(
        userId: userId,
        imageUrl: imageUrl,
        mealType: _selectedTime,
        timestamp: DateTime.now(),
      );

      // 3. 이미지 분석 (YOLOv7 및 OpenAI Assistant)
      _updateLoadingStatus(isLoading: true, status: '음식 분석 중...');
      try {
        final File imageFile = _selectedImage!;
        final Map<String, dynamic> yoloResult =
            await _analysisService.analyzeMealImageUsingYOLOv7(imageFile);
        final String base64Image = await _convertImageToBase64(imageFile);
        final Map<String, dynamic> openAIResult =
            await _analysisService.analyzeMealImageUsingAssistant(base64Image);

        if (!mounted) return;

        // 반환된 결과가 비어있는지 체크 후 에러 처리
        if (yoloResult.isEmpty || openAIResult.isEmpty) {
          throw Exception('이미지 분석에 실패했습니다.');
        }

        final Map<String, dynamic> analysisResult =
            _analysisService.mergeAnalysisResults(yoloResult, openAIResult);

        // 4. 분석 결과 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MealAnalysisScreen(
              mealRecord: mealRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
      } catch (e) {
        Logger.log('식사 분석 실패: $e');
        _showErrorSnackBar('분석 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      Logger.log('처리 중 오류 발생: $e');
      if (mounted) {
        _showErrorSnackBar('처리 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      _updateLoadingStatus(isLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '식사 기록하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              AnalysisStatus(
                status: _analysisStatus,
                isLoading: _isLoading,
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    MealTypeSelector(
                      selectedTime: _selectedTime,
                      onTimeSelected: (time) {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    MealImagePicker(
                      selectedImage: _selectedImage,
                      onImageSelected: (File image) {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                      onEditPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('카메라로 촬영하기'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('갤러리에서 선택하기'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeMealAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            '분석하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
