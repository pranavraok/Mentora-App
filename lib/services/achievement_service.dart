import 'package:flutter/foundation.dart';
import 'package:mentora_app/models/achievement.dart';
import 'package:mentora_app/services/local_storage_service.dart';

class AchievementService {
  final LocalStorageService _storage;
  static const String _achievementsKey = 'achievements';
  static const String _userAchievementsKey = 'user_achievements';

  AchievementService(this._storage);

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final jsonList = _storage.getJsonList(_achievementsKey);
      if (jsonList.isEmpty) {
        final sample = _generateSampleAchievements();
        await _saveAchievements(sample);
        return sample;
      }
      return jsonList.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final jsonList = _storage.getJsonList('${_userAchievementsKey}_$userId');
      return jsonList.map((json) => UserAchievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return [];
    }
  }

  Future<void> awardAchievement(String userId, String achievementId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      if (userAchievements.any((ua) => ua.achievementId == achievementId)) {
        return;
      }

      final newAchievement = UserAchievement(
        id: '${userId}_$achievementId',
        userId: userId,
        achievementId: achievementId,
        earnedAt: DateTime.now(),
      );

      userAchievements.add(newAchievement);
      await _storage.saveJsonList(
        '${_userAchievementsKey}_$userId',
        userAchievements.map((ua) => ua.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
    }
  }

  Future<void> _saveAchievements(List<Achievement> achievements) async {
    await _storage.saveJsonList(
      _achievementsKey,
      achievements.map((a) => a.toJson()).toList(),
    );
  }

  List<Achievement> _generateSampleAchievements() {
    final now = DateTime.now();
    return [
      Achievement(
        id: 'ach_first_login',
        title: 'Welcome Aboard',
        description: 'Complete your first login',
        iconEmoji: '👋',
        rarity: AchievementRarity.common,
        xpReward: 10,
        coinReward: 5,
        category: 'Milestones',
        criteria: {'type': 'login', 'count': 1},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_first_course',
        title: 'Scholar',
        description: 'Complete your first course',
        iconEmoji: '📚',
        rarity: AchievementRarity.common,
        xpReward: 50,
        coinReward: 20,
        category: 'Learning',
        criteria: {'type': 'course_complete', 'count': 1},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_first_project',
        title: 'Builder',
        description: 'Complete your first project',
        iconEmoji: '🏗️',
        rarity: AchievementRarity.uncommon,
        xpReward: 100,
        coinReward: 40,
        category: 'Projects',
        criteria: {'type': 'project_complete', 'count': 1},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_week_streak',
        title: 'Consistent Learner',
        description: 'Maintain a 7-day streak',
        iconEmoji: '🔥',
        rarity: AchievementRarity.uncommon,
        xpReward: 75,
        coinReward: 30,
        category: 'Streaks',
        criteria: {'type': 'streak', 'days': 7},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_level_5',
        title: 'Rising Star',
        description: 'Reach Level 5',
        iconEmoji: '⭐',
        rarity: AchievementRarity.rare,
        xpReward: 150,
        coinReward: 60,
        category: 'Levels',
        criteria: {'type': 'level', 'value': 5},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_level_10',
        title: 'Expert',
        description: 'Reach Level 10',
        iconEmoji: '💎',
        rarity: AchievementRarity.epic,
        xpReward: 300,
        coinReward: 120,
        category: 'Levels',
        criteria: {'type': 'level', 'value': 10},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_10_projects',
        title: 'Master Builder',
        description: 'Complete 10 projects',
        iconEmoji: '🏆',
        rarity: AchievementRarity.epic,
        xpReward: 500,
        coinReward: 200,
        category: 'Projects',
        criteria: {'type': 'project_complete', 'count': 10},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_legend',
        title: 'Legend',
        description: 'Reach Level 15',
        iconEmoji: '👑',
        rarity: AchievementRarity.legendary,
        xpReward: 1000,
        coinReward: 500,
        category: 'Levels',
        criteria: {'type': 'level', 'value': 15},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_night_owl',
        title: 'Night Owl',
        description: 'Study between 10 PM and 2 AM',
        iconEmoji: '🦉',
        rarity: AchievementRarity.uncommon,
        xpReward: 50,
        coinReward: 25,
        category: 'Fun',
        criteria: {'type': 'time', 'hours': [22, 23, 0, 1, 2]},
        createdAt: now,
        updatedAt: now,
      ),
      Achievement(
        id: 'ach_early_bird',
        title: 'Early Bird',
        description: 'Study between 5 AM and 7 AM',
        iconEmoji: '🌅',
        rarity: AchievementRarity.uncommon,
        xpReward: 50,
        coinReward: 25,
        category: 'Fun',
        criteria: {'type': 'time', 'hours': [5, 6, 7]},
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
