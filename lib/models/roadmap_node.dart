import 'package:cloud_firestore/cloud_firestore.dart';

enum NodeType {
  course,
  project,
  skillCheck,
  bossChallenge,
  restStop,
  bonus,
}

enum NodeStatus {
  locked,
  unlocked,
  inProgress,
  completed,
}

class RoadmapNode {
  final String id;
  final String roadmapId;
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
  final String region;
  final int order;
  final double progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoadmapNode({
    required this.id,
    required this.roadmapId,
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
    required this.region,
    required this.order,
    this.progress = 0.0,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoadmapNode.fromJson(Map<String, dynamic> json) {
    return RoadmapNode(
      id: json['id'] as String,
      roadmapId: json['roadmapId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: NodeType.values.byName(json['type'] as String),
      status: NodeStatus.values.byName(json['status'] as String? ?? 'locked'),
      xpReward: json['xpReward'] as int,
      coinReward: json['coinReward'] as int? ?? 0,
      estimatedHours: json['estimatedHours'] as int,
      prerequisites: (json['prerequisites'] as List<dynamic>?)?.cast<String>() ?? [],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      resourceUrl: json['resourceUrl'] as String?,
      providerName: json['providerName'] as String?,
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      region: json['region'] as String,
      order: json['order'] as int,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] is Timestamp
          ? (json['startedAt'] as Timestamp).toDate()
          : DateTime.parse(json['startedAt'] as String))
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : DateTime.parse(json['completedAt'] as String))
          : null,
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
    'roadmapId': roadmapId,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'xpReward': xpReward,
    'coinReward': coinReward,
    'estimatedHours': estimatedHours,
    'prerequisites': prerequisites,
    'skills': skills,
    'resourceUrl': resourceUrl,
    'providerName': providerName,
    'positionX': positionX,
    'positionY': positionY,
    'region': region,
    'order': order,
    'progress': progress,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  RoadmapNode copyWith({
    String? id,
    String? roadmapId,
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
    String? region,
    int? order,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoadmapNode(
      id: id ?? this.id,
      roadmapId: roadmapId ?? this.roadmapId,
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
      region: region ?? this.region,
      order: order ?? this.order,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
