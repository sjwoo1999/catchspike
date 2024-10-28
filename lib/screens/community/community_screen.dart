import 'package:flutter/material.dart';
import 'components/health_column_card.dart';
import 'components/exercise_video_card.dart';
import 'components/restaurant_card.dart';
import 'components/expert_card.dart';
import 'screens/column_detail_screen.dart';
import 'screens/video_detail_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/expert_detail_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('커뮤니티'),
          backgroundColor: const Color(0xFFE30547),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '건강 칼럼'),
              Tab(text: '운동 가이드'),
              Tab(text: '추천 맛집'),
              Tab(text: '전문가'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HealthColumnTab(),
            ExerciseVideoTab(),
            RestaurantTab(),
            ExpertTab(),
          ],
        ),
      ),
    );
  }
}

// 건강 칼럼 탭
class HealthColumnTab extends StatelessWidget {
  const HealthColumnTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return HealthColumnCard(
          title: '혈당 스파이크를 예방하는 식사 방법',
          author: '김영양 의사',
          date: '2024.10.28',
          imageUrl: 'assets/images/column_image.png',
          tags: ['#혈당관리', '#식사방법', '#건강'],
          onTap: () => _showColumnDetail(context),
        );
      },
    );
  }

  void _showColumnDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ColumnDetailScreen(
          title: '혈당 스파이크를 예방하는 식사 방법',
        ),
      ),
    );
  }
}

// 운동 가이드 탭
class ExerciseVideoTab extends StatelessWidget {
  const ExerciseVideoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ExerciseVideoCard(
          title: '식후 30분 스트레칭',
          trainer: '박트레이너',
          duration: '15:00',
          thumbnailUrl: 'assets/images/exercise_thumbnail.png',
          level: '초급',
          onTap: () => _showVideoDetail(context),
        );
      },
    );
  }

  void _showVideoDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoDetailScreen(
          title: '식후 30분 스트레칭',
        ),
      ),
    );
  }
}

// 추천 맛집 탭
class RestaurantTab extends StatelessWidget {
  const RestaurantTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return RestaurantCard(
          name: '건강한 샐러드',
          category: '샐러드 전문점',
          rating: 4.5,
          address: '서울시 강남구',
          imageUrl: 'assets/images/restaurant.png',
          healthScore: 85,
          onTap: () => _showRestaurantDetail(context),
        );
      },
    );
  }

  void _showRestaurantDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RestaurantDetailScreen(
          name: '건강한 샐러드',
        ),
      ),
    );
  }
}

// 전문가 탭
class ExpertTab extends StatelessWidget {
  const ExpertTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ExpertCard(
          name: '김영양 의사',
          specialty: '영양학 전문의',
          hospital: '건강한 병원',
          imageUrl: 'assets/images/expert.png',
          rating: 4.8,
          onTap: () => _showExpertDetail(context),
        );
      },
    );
  }

  void _showExpertDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpertDetailScreen(
          name: '김영양 의사',
        ),
      ),
    );
  }
}
