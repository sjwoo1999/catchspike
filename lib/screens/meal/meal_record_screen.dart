import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../../models/meal_record.dart';
import '../../services/meal_analysis_service.dart';
import 'meal_analysis_screen.dart';

class MealRecordScreen extends StatefulWidget {
  const MealRecordScreen({Key? key}) : super(key: key);

  @override
  State<MealRecordScreen> createState() => _MealRecordScreenState();
}

class _MealRecordScreenState extends State<MealRecordScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String _statusMessage = '';
  String _selectedMealType = 'breakfast'; // Default meal type

  // Initialize MealAnalysisService dynamically with ID Token
  Future<MealAnalysisService> initializeMealAnalysisService() async {
    final String idToken =
        await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';
    return MealAnalysisService(
      bucketName: 'catchspike-8163d.appspot.com', // Firebase Storage bucket
      firebaseAuthToken: idToken, // Dynamic ID Token
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Function to determine the correct content type based on file extension
  String getContentType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg'; // Default to JPEG
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) {
      setState(() => _statusMessage = '이미지를 선택해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '이미지 업로드 및 분석 중...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // ✅ UID 변환 (콜론 `:`을 `_`로 변경하여 Firebase 규칙 충돌 방지)
      final sanitizedUserId = user.uid.replaceAll(':', '_');

      // Debugging logs
      print("Current User: ${user.uid} → Sanitized User ID: $sanitizedUserId");

      // Dynamically initialize MealAnalysisService with ID token
      final analysisService = await initializeMealAnalysisService();

      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final fileName = "meal_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = 'meal_images/$sanitizedUserId/$dateStr/$fileName';

      // Debugging logs
      print("Uploading to: $filePath");

      final storageRef = FirebaseStorage.instance.ref(filePath);

      // Upload image with metadata
      await storageRef.putFile(
        _selectedImage!,
        SettableMetadata(contentType: getContentType(_selectedImage!.path)),
      );

      final imageUrl = await storageRef.getDownloadURL();

      // Process with analysis service
      final updatedMealRecord = await analysisService.uploadAndAnalyzeMeal(
        imageFile: _selectedImage!,
        userId: sanitizedUserId,
        mealType: _selectedMealType,
      );

      if (!mounted) return;

      setState(() => _statusMessage = '분석 완료!');
      // Navigate to the analysis result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MealAnalysisScreen(mealRecordId: updatedMealRecord.id),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '오류 발생: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 식사 기록'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(_statusMessage),
              ] else ...[
                Text(_statusMessage, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedMealType,
                items: const [
                  DropdownMenuItem(
                      child: Text('Breakfast'), value: 'breakfast'),
                  DropdownMenuItem(child: Text('Lunch'), value: 'lunch'),
                  DropdownMenuItem(child: Text('Dinner'), value: 'dinner'),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMealType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('이미지 선택'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                Image.file(_selectedImage!, height: 200),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _startAnalysis,
                child: const Text('분석 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
