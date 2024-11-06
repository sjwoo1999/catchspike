// lib/widgets/loading_indicator.dart
// 기존 커스텀 로딩 인디케이터 유지 (변경 없음)

// lib/widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import 'loading_indicator.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool useCustomIndicator;
  final Color backgroundColor;
  final bool dismissible;

  const LoadingOverlay({
    super.key,
    this.message,
    this.useCustomIndicator = true,
    this.backgroundColor = Colors.black54,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 오버레이
        Positioned.fill(
          child: ModalBarrier(
            dismissible: dismissible,
            color: backgroundColor,
          ),
        ),
        // 로딩 컨텐츠
        if (useCustomIndicator)
          const LoadingIndicator()
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
