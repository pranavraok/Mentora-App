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
  final List<String> skills;
  final Map<String, int> skillProficiency;
  final String? careerGoal;
  final String? careerTimeline;
  final int weeklyHours;
  final List<String> interests;
  final String? experienceLevel;
  final Map<String, String> socialLinks;

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
    this.skills = const [],
    this.skillProficiency = const {},
    this.careerGoal,
    this.careerTimeline,
    this.weeklyHours = 10,
    this.interests = const [],
    this.experienceLevel,
    this.socialLinks = const {},
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
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      skillProficiency: (json['skillProficiency'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
      ) ?? {},
      careerGoal: json['careerGoal'] as String?,
      careerTimeline: json['careerTimeline'] as String?,
      weeklyHours: json['weeklyHours'] as int? ?? 10,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      experienceLevel: json['experienceLevel'] as String?,
      socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
      ) ?? {},
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
    'skills': skills,
    'skillProficiency': skillProficiency,
    'careerGoal': careerGoal,
    'careerTimeline': careerTimeline,
    'weeklyHours': weeklyHours,
    'interests': interests,
    'experienceLevel': experienceLevel,
    'socialLinks': socialLinks,
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
    List<String>? skills,
    Map<String, int>? skillProficiency,
    String? careerGoal,
    String? careerTimeline,
    int? weeklyHours,
    List<String>? interests,
    String? experienceLevel,
    Map<String, String>? socialLinks,
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
      skills: skills ?? this.skills,
      skillProficiency: skillProficiency ?? this.skillProficiency,
      careerGoal: careerGoal ?? this.careerGoal,
      careerTimeline: careerTimeline ?? this.careerTimeline,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      interests: interests ?? this.interests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  int get xpForNextLevel => (level * 100 * (1 + level * 0.5)).toInt();
  double get levelProgress => xp / xpForNextLevel;

  String get levelTitle {
    if (level >= 15) return 'Legend';
    if (level >= 13) return 'Master';
    if (level >= 10) return 'Expert';
    if (level >= 7) return 'Skilled';
    if (level >= 4) return 'Apprentice';
    return 'Novice';
  }
}
