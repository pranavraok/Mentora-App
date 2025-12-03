import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {
  locked,
  unlocked,
  inProgress,
  completed,
}

enum ProjectDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

class ProjectTask {
  final String id;
  final String title;
  final bool isCompleted;

  ProjectTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };
}

class Project {
  final String id;
  final String title;
  final String description;
  final String overview;
  final ProjectStatus status;
  final ProjectDifficulty difficulty;
  final int xpReward;
  final int coinReward;
  final int estimatedHours;
  final List<String> requiredSkills;
  final List<String> learningOutcomes;
  final List<ProjectTask> tasks;
  final List<String> resources;
  final String? submissionUrl;
  final String? githubUrl;
  final int unlockLevel;
  final List<String> prerequisites;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.overview,
    this.status = ProjectStatus.locked,
    required this.difficulty,
    required this.xpReward,
    required this.coinReward,
    required this.estimatedHours,
    this.requiredSkills = const [],
    this.learningOutcomes = const [],
    this.tasks = const [],
    this.resources = const [],
    this.submissionUrl,
    this.githubUrl,
    this.unlockLevel = 1,
    this.prerequisites = const [],
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      overview: json['overview'] as String,
      status: ProjectStatus.values.byName(json['status'] as String? ?? 'locked'),
      difficulty: ProjectDifficulty.values.byName(json['difficulty'] as String),
      xpReward: json['xpReward'] as int,
      coinReward: json['coinReward'] as int,
      estimatedHours: json['estimatedHours'] as int,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)?.cast<String>() ?? [],
      learningOutcomes: (json['learningOutcomes'] as List<dynamic>?)?.cast<String>() ?? [],
      tasks: (json['tasks'] as List<dynamic>?)?.map((e) => ProjectTask.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      resources: (json['resources'] as List<dynamic>?)?.cast<String>() ?? [],
      submissionUrl: json['submissionUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      unlockLevel: json['unlockLevel'] as int? ?? 1,
      prerequisites: (json['prerequisites'] as List<dynamic>?)?.cast<String>() ?? [],
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
    'title': title,
    'description': description,
    'overview': overview,
    'status': status.name,
    'difficulty': difficulty.name,
    'xpReward': xpReward,
    'coinReward': coinReward,
    'estimatedHours': estimatedHours,
    'requiredSkills': requiredSkills,
    'learningOutcomes': learningOutcomes,
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'resources': resources,
    'submissionUrl': submissionUrl,
    'githubUrl': githubUrl,
    'unlockLevel': unlockLevel,
    'prerequisites': prerequisites,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    return completedCount / tasks.length;
  }
}
