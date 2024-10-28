import 'package:flutter/material.dart';

class ColumnDetailScreen extends StatelessWidget {
  final String title;

  const ColumnDetailScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 칼럼'),
        backgroundColor: const Color(0xFFE30547),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/column_image.png',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            const Text(
              '칼럼 내용이 여기에 표시됩니다...',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                height: 1.6,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
