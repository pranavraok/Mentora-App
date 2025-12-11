enum NotificationType {
  achievement,
  levelUp,
  projectUnlocked,
  projectCompleted,
  nodeCompleted,
  challengeCompleted,
  dailyChallengeReminder,
  streakMilestone,
  streakReminder,
  inactiveReminder,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.data,
    this.actionUrl,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['action_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static NotificationType _parseType(String type) {
    try {
      return NotificationType.values.firstWhere(
            (e) => e.name.toLowerCase() == type.toLowerCase(),
        orElse: () => NotificationType.system,
      );
    } catch (e) {
      return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'title': title,
    'message': message,
    'read': isRead,
    'data': data,
    'action_url': actionUrl,
    'created_at': createdAt.toIso8601String(),
  };

  String get icon {
    switch (type) {
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.levelUp:
        return '🎉';
      case NotificationType.projectUnlocked:
        return '🔓';
      case NotificationType.projectCompleted:
        return '🚀';
      case NotificationType.nodeCompleted:
        return '✅';
      case NotificationType.challengeCompleted:
        return '⭐';
      case NotificationType.dailyChallengeReminder:
        return '⏰';
      case NotificationType.streakMilestone:
        return '🔥';
      case NotificationType.streakReminder:
        return '🔥';
      case NotificationType.inactiveReminder:
        return '👋';
      case NotificationType.system:
        return '🔔';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

