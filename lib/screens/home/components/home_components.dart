import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import 'dart:math';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  String _getTimeBasedMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return '아침시간이에요!';
    } else if (hour >= 11 && hour < 14) {
      return '점심시간이에요!';
    } else if (hour >= 14 && hour < 17) {
      return '오후 시간이에요!';
    } else if (hour >= 17 && hour < 21) {
      return '저녁시간이에요!';
    } else {
      return '야식시간이에요!';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.month}월 ${now.day}일 ${_getKoreanWeekDay(now.weekday)}';
  }

  String _getKoreanWeekDay(int weekday) {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[weekday - 1];
  }

  String _getLastLoginMessage(DateTime? lastLoginAt) {
    if (lastLoginAt == null) return '처음 오셨군요! 환영합니다!';
    final now = DateTime.now();
    final difference = now.difference(lastLoginAt);
    if (difference.inDays >= 1) {
      return '${difference.inDays}일 만에 돌아오셨군요!';
    } else {
      return '오늘도 오셨군요!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final String userName = user?.name ?? '사용자';
        final String? profileImageUrl = user?.profileImageUrl;
        final DateTime? lastLoginAt = user?.lastLoginAt;

        const currentCalories = 1500;
        const recommendedCalories = 2500;
        const double percentage = currentCalories / recommendedCalories;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(userName, lastLoginAt),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _buildCalorieSection(
                  currentCalories: currentCalories,
                  recommendedCalories: recommendedCalories,
                  percentage: percentage,
                  profileImageUrl: profileImageUrl,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(String userName, DateTime? lastLoginAt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$userName님!',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getLastLoginMessage(lastLoginAt),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getTimeBasedMessage(),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSection({
    required int currentCalories,
    required int recommendedCalories,
    required double percentage,
    String? profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '현재 섭취 칼로리 / 권장 섭취 칼로리',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentCalories / $recommendedCalories kcal',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: ProfileBorderPainter(
                  percentage: percentage,
                  color: const Color(0xFFE30547),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileBorderPainter extends CustomPainter {
  final double percentage;
  final Color color;

  ProfileBorderPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProfileBorderPainter oldDelegate) =>
      percentage != oldDelegate.percentage || color != oldDelegate.color;
}
