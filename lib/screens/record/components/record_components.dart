import 'package:flutter/material.dart';
import '../../../widgets/common_widgets.dart';

class RecordContent extends StatelessWidget {
  RecordContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                '운동 기록',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // 운동 기록 리스트 또는 그리드를 여기에 추가
            ]),
          ),
        ),
      ],
    );
  }
}
