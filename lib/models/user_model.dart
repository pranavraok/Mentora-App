import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String? bio;
  final int xp;
  final int level;
  final int coins;
  final int streak;
  final DateTime? lastLoginDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Onboarding Data
  final String? education;
  final String? currentRole;
  final List<String> skills;
  final Map<String, int> skillProficiency;
  final String? careerGoal;
  final String? careerTimeline;
  final int weeklyHours;
  final List<String> interests;
  final String? experienceLevel;
  final String? learningStyle;
  final String? motivation;
  final Map<String, String> socialLinks;

  // Gamification
  final List<String> achievements;
  final List<String> badges;
  final Map<String, dynamic> statistics;
  final int totalLessonsCompleted;
  final int totalProjectsCompleted;
  final int currentStreak;
  final int longestStreak;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicUrl,
    this.bio,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.streak = 0,
    this.lastLoginDate,
    required this.createdAt,
    required this.updatedAt,
    this.education,
    this.currentRole,
    this.skills = const [],
    this.skillProficiency = const {},
    this.careerGoal,
    this.careerTimeline,
    this.weeklyHours = 10,
    this.interests = const [],
    this.experienceLevel,
    this.learningStyle,
    this.motivation,
    this.socialLinks = const {},
    this.achievements = const [],
    this.badges = const [],
    this.statistics = const {},
    this.totalLessonsCompleted = 0,
    this.totalProjectsCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profilePicUrl: json['profilePicUrl'] as String?,
      bio: json['bio'] as String?,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      coins: json['coins'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? (json['lastLoginDate'] is Timestamp
          ? (json['lastLoginDate'] as Timestamp).toDate()
          : DateTime.parse(json['lastLoginDate'] as String))
          : null,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
      education: json['education'] as String?,
      currentRole: json['currentRole'] as String?,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      skillProficiency: (json['skillProficiency'] as Map?)?.map(
            (key, value) => MapEntry(key, value as int),
      ) ??
          {},
      careerGoal: json['careerGoal'] as String?,
      careerTimeline: json['careerTimeline'] as String?,
      weeklyHours: json['weeklyHours'] as int? ?? 10,
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      experienceLevel: json['experienceLevel'] as String?,
      learningStyle: json['learningStyle'] as String?,
      motivation: json['motivation'] as String?,
      socialLinks: (json['socialLinks'] as Map?)?.map(
            (key, value) => MapEntry(key, value as String),
      ) ??
          {},
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      badges: (json['badges'] as List?)?.cast<String>() ?? [],
      statistics: (json['statistics'] as Map?)?.cast<String, dynamic>() ?? {},
      totalLessonsCompleted: json['totalLessonsCompleted'] as int? ?? 0,
      totalProjectsCompleted: json['totalProjectsCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'profilePicUrl': profilePicUrl,
    'bio': bio,
    'xp': xp,
    'level': level,
    'coins': coins,
    'streak': streak,
    'lastLoginDate': lastLoginDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'education': education,
    'currentRole': currentRole,
    'skills': skills,
    'skillProficiency': skillProficiency,
    'careerGoal': careerGoal,
    'careerTimeline': careerTimeline,
    'weeklyHours': weeklyHours,
    'interests': interests,
    'experienceLevel': experienceLevel,
    'learningStyle': learningStyle,
    'motivation': motivation,
    'socialLinks': socialLinks,
    'achievements': achievements,
    'badges': badges,
    'statistics': statistics,
    'totalLessonsCompleted': totalLessonsCompleted,
    'totalProjectsCompleted': totalProjectsCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
  };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePicUrl,
    String? bio,
    int? xp,
    int? level,
    int? coins,
    int? streak,
    DateTime? lastLoginDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? education,
    String? currentRole,
    List<String>? skills,
    Map<String, int>? skillProficiency,
    String? careerGoal,
    String? careerTimeline,
    int? weeklyHours,
    List<String>? interests,
    String? experienceLevel,
    String? learningStyle,
    String? motivation,
    Map<String, String>? socialLinks,
    List<String>? achievements,
    List<String>? badges,
    Map<String, dynamic>? statistics,
    int? totalLessonsCompleted,
    int? totalProjectsCompleted,
    int? currentStreak,
    int? longestStreak,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      education: education ?? this.education,
      currentRole: currentRole ?? this.currentRole,
      skills: skills ?? this.skills,
      skillProficiency: skillProficiency ?? this.skillProficiency,
      careerGoal: careerGoal ?? this.careerGoal,
      careerTimeline: careerTimeline ?? this.careerTimeline,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      interests: interests ?? this.interests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      motivation: motivation ?? this.motivation,
      socialLinks: socialLinks ?? this.socialLinks,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
      statistics: statistics ?? this.statistics,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalProjectsCompleted: totalProjectsCompleted ?? this.totalProjectsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  // ✅ FIXED: XP required for each level (your custom progression)
  static int getXPRequiredForLevel(int level) {
    switch (level) {
      case 1: return 1000;      // Level 1: 0-1000 (need 1000 XP)
      case 2: return 1000;      // Level 2: 1001-2000 (need 1000 more)
      case 3: return 1500;      // Level 3: 2001-3500 (need 1500 more)
      case 4: return 1500;      // Level 4: 3501-5000 (need 1500 more)
      case 5: return 2000;      // Level 5: 5001-7000 (need 2000 more)
      case 6: return 2500;      // Level 6: 7001-9500 (need 2500 more)
      case 7: return 3000;      // Level 7: 9501-12500 (need 3000 more)
      case 8: return 3500;      // Level 8: 12501-16000 (need 3500 more)
      case 9: return 4000;      // Level 9: 16001-20000 (need 4000 more)
      case 10: return 5000;     // Level 10: 20001-25000 (need 5000 more)
      default:
      // After level 10: each level needs 5000 + (level-10)*500 more XP
        return 5000 + ((level - 10) * 500);
    }
  }

  // ✅ FIXED: XP required for NEXT level (not total)
  int get xpForNextLevel => getXPRequiredForLevel(level);

  // ✅ NEW: Get XP within current level only
  int get currentLevelXP {
    int cumulativeXP = 0;
    for (int i = 1; i < level; i++) {
      cumulativeXP += getXPRequiredForLevel(i);
    }
    return xp - cumulativeXP;
  }

  // ✅ FIXED: Progress based on current level XP
  double get levelProgress => (currentLevelXP / xpForNextLevel).clamp(0.0, 1.0);

  // Level Title System
  String get levelTitle {
    if (level >= 50) return 'Legendary Hero';
    if (level >= 40) return 'Grand Master';
    if (level >= 30) return 'Champion';
    if (level >= 25) return 'Legend';
    if (level >= 20) return 'Master';
    if (level >= 15) return 'Expert';
    if (level >= 10) return 'Professional';
    if (level >= 7) return 'Skilled';
    if (level >= 5) return 'Apprentice';
    if (level >= 3) return 'Student';
    return 'Novice';
  }

  // Achievement Tracking
  bool hasAchievement(String achievementId) => achievements.contains(achievementId);
  bool hasBadge(String badgeId) => badges.contains(badgeId);

  // Statistics Helpers
  int get totalActiveDays => statistics['totalActiveDays'] as int? ?? 0;
  int get totalTimeSpentMinutes => statistics['totalTimeSpent'] as int? ?? 0;
  double get averageSessionTime {
    final sessions = statistics['totalSessions'] as int? ?? 1;
    return totalTimeSpentMinutes / sessions;
  }

  // Streak Calculations
  bool get isOnStreak => currentStreak > 0;
  bool get hasStreakRecord => longestStreak > 0;
  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    return '⚡';
  }

  // Completion Stats
  double get completionRate {
    final total = totalLessonsCompleted + totalProjectsCompleted;
    if (total == 0) return 0.0;
    return totalProjectsCompleted / total;
  }

  // User Status
  bool get isNewUser => level == 1 && xp < 100;
  bool get isActiveUser => currentStreak >= 3;
  bool get isPowerUser => level >= 10 && currentStreak >= 7;

  // Profile Completeness
  int get profileCompleteness {
    int score = 0;
    if (education != null && education!.isNotEmpty) score += 10;
    if (currentRole != null && currentRole!.isNotEmpty) score += 10;
    if (skills.length >= 3) score += 15;
    if (careerGoal != null && careerGoal!.isNotEmpty) score += 15;
    if (interests.length >= 3) score += 10;
    if (experienceLevel != null) score += 10;
    if (learningStyle != null) score += 10;
    if (motivation != null) score += 10;
    if (bio != null && bio!.isNotEmpty) score += 10;
    return score;
  }

  bool get isProfileComplete => profileCompleteness == 100;

  // Skill Level Helpers
  String getSkillLevel(String skill) {
    final proficiency = skillProficiency[skill] ?? 0;
    if (proficiency >= 80) return 'Expert';
    if (proficiency >= 60) return 'Advanced';
    if (proficiency >= 40) return 'Intermediate';
    if (proficiency >= 20) return 'Beginner';
    return 'Novice';
  }

  // Next Level Info
  int get xpNeededForNextLevel => xpForNextLevel - currentLevelXP;
  String get nextLevelTitle {
    final nextLevel = level + 1;
    if (nextLevel >= 50) return 'Legendary Hero';
    if (nextLevel >= 40) return 'Grand Master';
    if (nextLevel >= 30) return 'Champion';
    if (nextLevel >= 25) return 'Legend';
    if (nextLevel >= 20) return 'Master';
    if (nextLevel >= 15) return 'Expert';
    if (nextLevel >= 10) return 'Professional';
    if (nextLevel >= 7) return 'Skilled';
    if (nextLevel >= 5) return 'Apprentice';
    if (nextLevel >= 3) return 'Student';
    return 'Novice';
  }

  // Rank Calculation (for leaderboard)
  String get rank {
    if (xp >= 50000) return 'S+';
    if (xp >= 30000) return 'S';
    if (xp >= 20000) return 'A+';
    if (xp >= 15000) return 'A';
    if (xp >= 10000) return 'B+';
    if (xp >= 7000) return 'B';
    if (xp >= 5000) return 'C+';
    if (xp >= 3000) return 'C';
    if (xp >= 1000) return 'D';
    return 'E';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, level: $level, xp: $xp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
