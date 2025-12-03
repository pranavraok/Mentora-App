import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? profilePicUrl;
  final int xp;
  final int level;
  final int rank;
  final int projectsCompleted;
  final int achievementsEarned;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.profilePicUrl,
    required this.xp,
    required this.level,
    required this.rank,
    required this.projectsCompleted,
    required this.achievementsEarned,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      profilePicUrl: json['profilePicUrl'] as String?,
      xp: json['xp'] as int,
      level: json['level'] as int,
      rank: json['rank'] as int,
      projectsCompleted: json['projectsCompleted'] as int,
      achievementsEarned: json['achievementsEarned'] as int,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'profilePicUrl': profilePicUrl,
    'xp': xp,
    'level': level,
    'rank': rank,
    'projectsCompleted': projectsCompleted,
    'achievementsEarned': achievementsEarned,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
