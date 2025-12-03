import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum AchievementCategory {
  learning,
  projects,
  social,
  consistency,
  milestones,
  skills,
  special,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementRarity rarity;
  final int xpReward;
  final int coinReward;
  final String category;
  final Map<String, dynamic> criteria;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSecret;
  final String? unlockedMessage;
  final List<String> prerequisites;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.rarity,
    required this.xpReward,
    required this.coinReward,
    required this.category,
    required this.criteria,
    required this.createdAt,
    required this.updatedAt,
    this.isSecret = false,
    this.unlockedMessage,
    this.prerequisites = const [],
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconEmoji: json['iconEmoji'] as String,
      rarity: AchievementRarity.values.byName(json['rarity'] as String),
      xpReward: json['xpReward'] as int,
      coinReward: json['coinReward'] as int,
      category: json['category'] as String,
      criteria: json['criteria'] as Map<String, dynamic>,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
      isSecret: json['isSecret'] as bool? ?? false,
      unlockedMessage: json['unlockedMessage'] as String?,
      prerequisites: (json['prerequisites'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconEmoji': iconEmoji,
    'rarity': rarity.name,
    'xpReward': xpReward,
    'coinReward': coinReward,
    'category': category,
    'criteria': criteria,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSecret': isSecret,
    'unlockedMessage': unlockedMessage,
    'prerequisites': prerequisites,
  };

  // Rarity Color
  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF808080); // Gray
      case AchievementRarity.uncommon:
        return const Color(0xFF4CAF50); // Green
      case AchievementRarity.rare:
        return const Color(0xFF2196F3); // Blue
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0); // Purple
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700); // Gold
      case AchievementRarity.mythic:
        return const Color(0xFFFF1744); // Red
    }
  }

  // Rarity Gradient
  Gradient get rarityGradient {
    switch (rarity) {
      case AchievementRarity.common:
        return const LinearGradient(
          colors: [Color(0xFF808080), Color(0xFF606060)],
        );
      case AchievementRarity.uncommon:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
        );
      case AchievementRarity.rare:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        );
      case AchievementRarity.epic:
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        );
      case AchievementRarity.legendary:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case AchievementRarity.mythic:
        return const LinearGradient(
          colors: [Color(0xFFFF1744), Color(0xFFC51162)],
        );
    }
  }

  // Rarity Display Name
  String get rarityDisplayName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
      case AchievementRarity.mythic:
        return 'Mythic';
    }
  }

  // Total Reward Value
  int get totalRewardValue => xpReward + (coinReward * 10);

  // Category Icon
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'learning':
        return Icons.school;
      case 'projects':
        return Icons.construction;
      case 'social':
        return Icons.people;
      case 'consistency':
        return Icons.local_fire_department;
      case 'milestones':
        return Icons.flag;
      case 'skills':
        return Icons.auto_awesome;
      case 'special':
        return Icons.stars;
      default:
        return Icons.emoji_events;
    }
  }

  // Check if achievement has prerequisites
  bool get hasPrerequisites => prerequisites.isNotEmpty;

  // Get display description (hide for secret achievements)
  String get displayDescription {
    if (isSecret) {
      return '??? Unlock this secret achievement to reveal its description';
    }
    return description;
  }

  // Get display title (hide for secret achievements)
  String get displayTitle {
    if (isSecret) {
      return '??? Secret Achievement';
    }
    return title;
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconEmoji,
    AchievementRarity? rarity,
    int? xpReward,
    int? coinReward,
    String? category,
    Map<String, dynamic>? criteria,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSecret,
    String? unlockedMessage,
    List<String>? prerequisites,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      rarity: rarity ?? this.rarity,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      category: category ?? this.category,
      criteria: criteria ?? this.criteria,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSecret: isSecret ?? this.isSecret,
      unlockedMessage: unlockedMessage ?? this.unlockedMessage,
      prerequisites: prerequisites ?? this.prerequisites,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, rarity: ${rarity.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedAt;
  final bool isNew;
  final int progress;
  final bool isPinned;
  final String? shareMessage;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.isNew = true,
    this.progress = 100,
    this.isPinned = false,
    this.shareMessage,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      earnedAt: json['earnedAt'] is Timestamp
          ? (json['earnedAt'] as Timestamp).toDate()
          : DateTime.parse(json['earnedAt'] as String),
      isNew: json['isNew'] as bool? ?? true,
      progress: json['progress'] as int? ?? 100,
      isPinned: json['isPinned'] as bool? ?? false,
      shareMessage: json['shareMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'achievementId': achievementId,
    'earnedAt': earnedAt.toIso8601String(),
    'isNew': isNew,
    'progress': progress,
    'isPinned': isPinned,
    'shareMessage': shareMessage,
  };

  // Time since earned
  Duration get timeSinceEarned => DateTime.now().difference(earnedAt);

  // Display time string
  String get earnedTimeAgo {
    final duration = timeSinceEarned;

    if (duration.inDays > 365) {
      final years = (duration.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (duration.inDays > 30) {
      final months = (duration.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if earned today
  bool get earnedToday {
    final now = DateTime.now();
    return earnedAt.year == now.year &&
        earnedAt.month == now.month &&
        earnedAt.day == now.day;
  }

  // Check if earned this week
  bool get earnedThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return earnedAt.isAfter(weekStart);
  }

  // Is completed
  bool get isCompleted => progress >= 100;

  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? earnedAt,
    bool? isNew,
    int? progress,
    bool? isPinned,
    String? shareMessage,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      earnedAt: earnedAt ?? this.earnedAt,
      isNew: isNew ?? this.isNew,
      progress: progress ?? this.progress,
      isPinned: isPinned ?? this.isPinned,
      shareMessage: shareMessage ?? this.shareMessage,
    );
  }

  @override
  String toString() {
    return 'UserAchievement(id: $id, achievementId: $achievementId, earnedAt: $earnedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Achievement Progress Tracking
class AchievementProgress {
  final String achievementId;
  final String userId;
  final int currentProgress;
  final int targetProgress;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  AchievementProgress({
    required this.achievementId,
    required this.userId,
    required this.currentProgress,
    required this.targetProgress,
    required this.lastUpdated,
    this.metadata = const {},
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] as String,
      userId: json['userId'] as String,
      currentProgress: json['currentProgress'] as int,
      targetProgress: json['targetProgress'] as int,
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.parse(json['lastUpdated'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'userId': userId,
    'currentProgress': currentProgress,
    'targetProgress': targetProgress,
    'lastUpdated': lastUpdated.toIso8601String(),
    'metadata': metadata,
  };

  // Progress percentage
  double get progressPercentage {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  // Is completed
  bool get isCompleted => currentProgress >= targetProgress;

  // Remaining progress
  int get remainingProgress => (targetProgress - currentProgress).clamp(0, targetProgress);

  AchievementProgress copyWith({
    String? achievementId,
    String? userId,
    int? currentProgress,
    int? targetProgress,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return AchievementProgress(
      achievementId: achievementId ?? this.achievementId,
      userId: userId ?? this.userId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Pre-defined Achievement Templates
class AchievementTemplates {
  static Achievement firstLesson = Achievement(
    id: 'first_lesson',
    title: 'First Steps',
    description: 'Complete your first lesson',
    iconEmoji: '🎓',
    rarity: AchievementRarity.common,
    xpReward: 50,
    coinReward: 10,
    category: 'learning',
    criteria: {'lessonsCompleted': 1},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Achievement weekWarrior = Achievement(
    id: 'week_warrior',
    title: 'Week Warrior',
    description: 'Maintain a 7-day learning streak',
    iconEmoji: '🔥',
    rarity: AchievementRarity.uncommon,
    xpReward: 200,
    coinReward: 50,
    category: 'consistency',
    criteria: {'streak': 7},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Achievement projectMaster = Achievement(
    id: 'project_master',
    title: 'Project Master',
    description: 'Complete 10 projects',
    iconEmoji: '🏗️',
    rarity: AchievementRarity.rare,
    xpReward: 500,
    coinReward: 100,
    category: 'projects',
    criteria: {'projectsCompleted': 10},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Achievement levelTen = Achievement(
    id: 'level_ten',
    title: 'Rising Star',
    description: 'Reach Level 10',
    iconEmoji: '⭐',
    rarity: AchievementRarity.epic,
    xpReward: 1000,
    coinReward: 250,
    category: 'milestones',
    criteria: {'level': 10},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Achievement secretLegend = Achievement(
    id: 'secret_legend',
    title: 'Hidden Legend',
    description: 'Discover the secret path to mastery',
    iconEmoji: '🌟',
    rarity: AchievementRarity.legendary,
    xpReward: 5000,
    coinReward: 1000,
    category: 'special',
    criteria: {'secret': true},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isSecret: true,
    unlockedMessage: 'You\'ve discovered the secret! True mastery awaits.',
  );
}
