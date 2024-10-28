// lib/screens/achievements/models/badge.dart
import 'package:flutter/material.dart';

class AchievementBadge {
  // Badge -> AchievementBadge로 이름 변경
  final String name;
  final String emoji;
  final Color color;
  final String description;
  final DateTime earnedDate;

  const AchievementBadge({
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
    required this.earnedDate,
  });
}

// 샘플 뱃지 데이터
final List<AchievementBadge> achievementBadges = [
  // badges -> achievementBadges로 이름 변경
  AchievementBadge(
    name: '첫 식사 기록',
    emoji: '🎯',
    color: Colors.blue,
    description: '첫 번째 식사를 기록했어요!',
    earnedDate: DateTime.now(),
  ),
  AchievementBadge(
    name: '일주일 연속',
    emoji: '🔥',
    color: Colors.orange,
    description: '7일 연속으로 식사를 기록했어요!',
    earnedDate: DateTime.now(),
  ),
  AchievementBadge(
    name: '건강 달인',
    emoji: '🏆',
    color: Colors.purple,
    description: '건강 점수 90점 이상을 달성했어요!',
    earnedDate: DateTime.now(),
  ),
  AchievementBadge(
    name: '영양 균형',
    emoji: '🥗',
    color: Colors.green,
    description: '균형 잡힌 식사를 달성했어요!',
    earnedDate: DateTime.now(),
  ),
  AchievementBadge(
    name: '시간 지킴이',
    emoji: '⏰',
    color: Colors.red,
    description: '한 주 동안 식사 시간을 잘 지켰어요!',
    earnedDate: DateTime.now(),
  ),
  AchievementBadge(
    name: '목표 달성',
    emoji: '🎉',
    color: Colors.amber,
    description: '이번 달 건강 목표를 달성했어요!',
    earnedDate: DateTime.now(),
  ),
];
