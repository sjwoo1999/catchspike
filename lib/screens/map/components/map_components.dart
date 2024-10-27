import 'package:flutter/material.dart';
import '../../../widgets/common_widgets.dart';

class MapContent extends StatelessWidget {
  MapContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '지도 화면',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: '위치 새로고침',
            onPressed: () {
              // 위치 새로고침 로직
            },
          ),
        ],
      ),
    );
  }
}
