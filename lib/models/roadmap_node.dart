enum NodeType {
  course,
  project,
  skillCheck,
  bossChallenge,
  restStop,
  bonus,
  milestone,
  checkpoint,
  challenge,
  skill,
}

enum NodeStatus {
  locked,
  unlocked,
  inProgress,
  completed,
}

class RoadmapNode {
  final String id;
  final String userId;
  final String title;
  final String description;
  final NodeType type;
  final NodeStatus status;
  final int xpReward;
  final int coinReward;
  final int estimatedHours;
  final List<String> prerequisites;
  final List<String> skills;
  final String? resourceUrl;
  final String? providerName;
  final double? positionX;
  final double? positionY;
  final String? backgroundTheme;
  final String? iconUrl;
  final String? difficulty;
  final int progressPercentage;
  final int orderIndex;
  final String? externalUrl;
  final List<String> resourceLinks;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  RoadmapNode({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    this.status = NodeStatus.locked,
    required this.xpReward,
    this.coinReward = 0,
    required this.estimatedHours,
    this.prerequisites = const [],
    this.skills = const [],
    this.resourceUrl,
    this.providerName,
    this.positionX,
    this.positionY,
    this.backgroundTheme,
    this.iconUrl,
    this.difficulty,
    this.progressPercentage = 0,
    this.orderIndex = 0,
    this.externalUrl,
    this.resourceLinks = const [],
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory RoadmapNode.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function for safe string extraction
      String? safeString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        return value.toString();
      }

      // Helper function for safe int extraction
      int safeInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      // Helper function for safe double extraction
      double? safeDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }

      return RoadmapNode(
        id: safeString(json['id']) ?? '',
        userId: safeString(json['user_id']) ?? '',
        title: safeString(json['title']) ?? 'Untitled',
        description: safeString(json['description']) ?? '',
        type: _parseNodeType(safeString(json['node_type']) ?? 'course'),
        status: _parseStatus(safeString(json['status']) ?? 'locked'),
        xpReward: safeInt(json['xp_reward']),
        coinReward: safeInt(json['coin_reward']),
        estimatedHours: safeInt(json['time_estimate_hours']),
        prerequisites: _parseStringList(json['prerequisites']),
        skills: _parseStringList(json['required_skills']),
        resourceUrl: safeString(json['external_url']),
        providerName: safeString(json['provider_name']),
        positionX: safeDouble(json['position_x']),
        positionY: safeDouble(json['position_y']),
        backgroundTheme: safeString(json['background_theme']),
        iconUrl: safeString(json['icon_url']),
        difficulty: safeString(json['difficulty']),
        progressPercentage: safeInt(json['progress_percentage']),
        orderIndex: safeInt(json['order_index']),
        externalUrl: safeString(json['external_url']),
        resourceLinks: _parseStringList(json['resource_links']),
        startedAt: _parseDateTime(json['started_at']),
        completedAt: _parseDateTime(json['completed_at']),
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing RoadmapNode from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return null;
    } catch (e) {
      print('Error parsing DateTime from value: $value');
      return null;
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    try {
      if (value is List) {
        return value
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (value is String && value.isNotEmpty) {
        // Handle comma-separated strings
        return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing string list from value: $value');
      return [];
    }
  }

  static NodeType _parseNodeType(String type) {
    switch (type.toLowerCase().trim()) {
      case 'course':
        return NodeType.course;
      case 'project':
        return NodeType.project;
      case 'skill':
      case 'skill_check':
      case 'skillcheck':
        return NodeType.skillCheck;
      case 'challenge':
      case 'boss_challenge':
      case 'bosschallenge':
        return NodeType.bossChallenge;
      case 'milestone':
        return NodeType.milestone;
      case 'checkpoint':
        return NodeType.checkpoint;
      case 'rest_stop':
      case 'reststop':
        return NodeType.restStop;
      case 'bonus':
        return NodeType.bonus;
      default:
        print('Unknown node type: $type, defaulting to course');
        return NodeType.course;
    }
  }

  static NodeStatus _parseStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed':
        return NodeStatus.completed;
      case 'in_progress':
      case 'inprogress':
      case 'in progress':
        return NodeStatus.inProgress;
      case 'unlocked':
        return NodeStatus.unlocked;
      case 'locked':
      default:
        return NodeStatus.locked;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'node_type': type.name,
    'status': status.name,
    'xp_reward': xpReward,
    'coin_reward': coinReward,
    'time_estimate_hours': estimatedHours,
    'prerequisites': prerequisites,
    'required_skills': skills,
    'external_url': resourceUrl,
    'provider_name': providerName,
    'position_x': positionX,
    'position_y': positionY,
    'background_theme': backgroundTheme,
    'icon_url': iconUrl,
    'difficulty': difficulty,
    'progress_percentage': progressPercentage,
    'order_index': orderIndex,
    'resource_links': resourceLinks,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  RoadmapNode copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    NodeType? type,
    NodeStatus? status,
    int? xpReward,
    int? coinReward,
    int? estimatedHours,
    List<String>? prerequisites,
    List<String>? skills,
    String? resourceUrl,
    String? providerName,
    double? positionX,
    double? positionY,
    String? backgroundTheme,
    String? iconUrl,
    String? difficulty,
    int? progressPercentage,
    int? orderIndex,
    String? externalUrl,
    List<String>? resourceLinks,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return RoadmapNode(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      prerequisites: prerequisites ?? this.prerequisites,
      skills: skills ?? this.skills,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      providerName: providerName ?? this.providerName,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
      iconUrl: iconUrl ?? this.iconUrl,
      difficulty: difficulty ?? this.difficulty,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      orderIndex: orderIndex ?? this.orderIndex,
      externalUrl: externalUrl ?? this.externalUrl,
      resourceLinks: resourceLinks ?? this.resourceLinks,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
