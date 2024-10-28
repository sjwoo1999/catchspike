import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'components/achievement_badge.dart';
import 'components/stats_card.dart';
import 'components/streak_card.dart';
import 'components/share_achievement_card.dart';

// 컨트롤러 정의
class AchievementsController extends GetxController {
  final RxBool isCollapsed = false.obs;
  final RxInt currentStreak = 7.obs;
  final RxInt longestStreak = 14.obs;
  final RxInt totalMeals = 42.obs;
  final RxInt averageScore = 85.obs;
  final RxInt perfectDays = 5.obs;

  void updateCollapseState(bool collapsed) {
    isCollapsed.value = collapsed;
  }

  void updateStats({
    int? streak,
    int? longest,
    int? meals,
    int? score,
    int? perfect,
  }) {
    if (streak != null) currentStreak.value = streak;
    if (longest != null) longestStreak.value = longest;
    if (meals != null) totalMeals.value = meals;
    if (score != null) averageScore.value = score;
    if (perfect != null) perfectDays.value = perfect;
  }

  void refreshData() {
    // API 호출 또는 데이터 새로고침 로직
    update();
  }
}

class AchievementsScreen extends StatelessWidget {
  AchievementsScreen({super.key}) {
    // 컨트롤러 초기화
    Get.put(AchievementsController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AchievementsController>();

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
                controller.updateCollapseState(appBarHeight < 120);

                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Obx(() => controller.isCollapsed.value
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
                        )),
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
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 컨텐츠
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
                  Obx(() => StreakCard(
                        currentStreak: controller.currentStreak.value,
                        longestStreak: controller.longestStreak.value,
                      )),
                  const SizedBox(height: 24),
                  Obx(() => StatsCard(
                        totalMeals: controller.totalMeals.value,
                        averageScore: controller.averageScore.value,
                        perfectDays: controller.perfectDays.value,
                      )),
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
    Get.find<AchievementsController>().refreshData(); // 공유 후 데이터 새로고침
  }
}
