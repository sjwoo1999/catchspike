// lib/screens/meal/components/meal_image_picker.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../utils/logger.dart';

class MealImagePicker extends StatelessWidget {
  final File? selectedImage;
  final Function(File) onImageSelected;
  final VoidCallback onEditPressed;

  const MealImagePicker({
    Key? key,
    required this.selectedImage,
    required this.onImageSelected,
    required this.onEditPressed,
  }) : super(key: key);

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(File(image.path));
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      Logger.log('이미지 선택 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _showImagePickerBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildPickerOption(
              context: context,
              icon: Icons.camera_alt,
              title: '카메라로 촬영하기',
              onTap: () => _pickImage(ImageSource.camera, context),
            ),
            _buildPickerOption(
              context: context,
              icon: Icons.photo_library,
              title: '갤러리에서 선택하기',
              onTap: () => _pickImage(ImageSource.gallery, context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedImage == null) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '카메라로 모든 음식이\n보이게 찍어주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showImagePickerBottomSheet(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '여기를 눌러 사진을 찍어주세요',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  selectedImage!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onEditPressed,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
