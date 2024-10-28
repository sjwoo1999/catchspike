import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import 'dart:math';
import '../screens/meal_record_screen.dart';

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

  String _getMealButtonText() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return '아침 식사 기록하기';
    } else if (hour >= 11 && hour < 14) {
      return '점심 식사 기록하기';
    } else if (hour >= 17 && hour < 21) {
      return '저녁 식사 기록하기';
    } else {
      return '식사 기록하기';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final String userName = user?.kakaoAccount?.profile?.nickname ?? '사용자';
        final String? profileImageUrl =
            user?.kakaoAccount?.profile?.profileImageUrl;

        const currentCalories = 1500;
        const recommendedCalories = 2500;
        final double percentage = currentCalories / recommendedCalories;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 첫 번째 섹션
                Container(
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
                        _getTimeBasedMessage(),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '어떤 맛있는 메뉴로\n에너지를 충전하셨나요? 🍽️',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // 식사 기록 기능 구현
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MealRecordScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE30547),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _getMealButtonText(),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 날짜 섹션
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

                // 칼로리 및 프로필 섹션
                Container(
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
                                    : const AssetImage(
                                            'assets/images/default_profile.png')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      -pi / 2, // 시작 각도 (12시 방향)
      2 * pi * percentage, // 진행도에 따른 호의 길이
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProfileBorderPainter oldDelegate) =>
      percentage != oldDelegate.percentage || color != oldDelegate.color;
}
