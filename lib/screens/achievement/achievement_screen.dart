// lib/screens/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import 'components/achievement_badge.dart';
import 'components/stats_card.dart';
import 'components/streak_card.dart';
import 'components/share_achievement_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFE30547),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double appBarHeight = constraints.biggest.height;
                // appBarHeight가 kToolbarHeight에 가까워지면 타이틀만 표시
                final bool isCollapsed = appBarHeight < 120;

                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: isCollapsed
                      ? const Text(
                          '나의 건강 성과',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '나의 건강 성과',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFFE30547),
                          Color(0xFF8E0537),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🎉',
                            style: TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '건강한 식습관 달성 중!',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 40), // 텍스트 겹침 방지를 위한 여백
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 나머지 내용은 동일
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '최근 획득한 뱃지',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RecentBadgeGrid(),
                  const SizedBox(height: 24),
                  const StreakCard(
                    currentStreak: 7,
                    longestStreak: 14,
                  ),
                  const SizedBox(height: 24),
                  const StatsCard(
                    totalMeals: 42,
                    averageScore: 85,
                    perfectDays: 5,
                  ),
                  const SizedBox(height: 24),
                  ShareAchievementCard(
                    onShare: () => _shareToInstagram(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareToInstagram(BuildContext context) {
    // 인스타그램 공유 로직
  }
}
