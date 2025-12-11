class UserActivity {
  final String id;
  final String userId;
  final String activityType;
  final String title;
  final String? description;
  final int xpEarned;
  final String? icon;
  final String? color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  UserActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.title,
    this.description,
    required this.xpEarned,
    this.icon,
    this.color,
    this.metadata,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      xpEarned: json['xp_earned'] as int? ?? 0,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
  }

  String? get badgeText {
    if (xpEarned > 0) {
      return '+$xpEarned XP';
    }
    return null;
  }
}
