// lib/screens/meal/meal_record_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:catchspike/services/firebase_service.dart';
import 'package:catchspike/services/meal_analysis_service.dart';
import 'package:catchspike/models/meal_record.dart';
import 'package:catchspike/utils/logger.dart';
import 'dart:io';
import 'components/meal_image_picker.dart';
import 'components/meal_type_selector.dart';
import 'components/analysis_status.dart';
import 'meal_analysis_screen.dart';

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
      ),
    );
  }

  void _updateAnalysisStatus(String status) {
    if (mounted) {
      setState(() {
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

  Future<void> _analyzeMealAndSave() async {
    if (_selectedImage == null || _selectedTime.isEmpty) {
      _showErrorSnackBar('이미지와 식사 시간을 모두 선택해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisStatus = '이미지 업로드 중...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      // 1. 이미지 업로드
      _updateAnalysisStatus('이미지 업로드 중...');
      final imageUrl =
          await _firebaseService.uploadMealImage(_selectedImage!, user.uid);

      // 2. ChatGPT로 이미지 분석
      _updateAnalysisStatus('음식 분석 중...');
      final analysisResult = await _analysisService.analyzeMealImage(imageUrl);

      // 3. 식사 기록 생성
      final mealRecord = MealRecord(
        userId: user.uid,
        imageUrl: imageUrl,
        mealType: _selectedTime,
        timestamp: DateTime.now(),
        analysisResult: analysisResult,
      );

      // 4. 데이터베이스 저장
      _updateAnalysisStatus('분석 결과 저장 중...');
      await _firebaseService.saveMealRecord(mealRecord);

      if (!mounted) return;

      // 5. 분석 결과 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MealAnalysisScreen(mealRecord: mealRecord),
        ),
      );
    } catch (e) {
      Logger.log('식사 분석 실패: $e');
      if (mounted) {
        _showErrorSnackBar('분석 중 오류가 발생했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _analysisStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
                                    top: Radius.circular(20)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.camera_alt),
                                    title: Text('카메라로 촬영하기'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.photo_library),
                                    title: Text('갤러리에서 선택하기'),
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
