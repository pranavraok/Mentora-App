import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
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
  };
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedAt;
  final bool isNew;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.isNew = true,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'achievementId': achievementId,
    'earnedAt': earnedAt.toIso8601String(),
    'isNew': isNew,
  };
}
