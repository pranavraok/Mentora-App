class DailyChallenge {
  final String id;
  final String userId;
  final String challengeType;
  final String title;
  final String? description;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final int coinReward;
  final DateTime expiresAt;
  final bool completed;

  DailyChallenge({
    required this.id,
    required this.userId,
    required this.challengeType,
    required this.title,
    this.description,
    required this.targetValue,
    required this.currentValue,
    required this.xpReward,
    required this.coinReward,
    required this.expiresAt,
    required this.completed,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeType: json['challenge_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int? ?? 0,
      xpReward: json['xp_reward'] as int,
      coinReward: json['coin_reward'] as int,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      completed: json['completed'] as bool? ?? false,
    );
  }

  double get progress => currentValue / targetValue;

  Duration get timeLeft => expiresAt.difference(DateTime.now());

  String get timeLeftString {
    final duration = timeLeft;
    if (duration.isNegative) return 'Expired';
    if (duration.inDays > 0) return '${duration.inDays}d ${duration.inHours % 24}h left';
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m left';
    return 'Ending soon';
  }
}
