import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {
  all, // For filtering - shows all projects
  locked,
  unlocked,
  inProgress,
  completed,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.all:
        return 'All';
      case ProjectStatus.locked:
        return 'Locked';
      case ProjectStatus.unlocked:
        return 'Unlocked';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  // Parse from Supabase database values
  static ProjectStatus fromString(String? value) {
    if (value == null) return ProjectStatus.unlocked;

    switch (value.toLowerCase()) {
      case 'all':
        return ProjectStatus.all;
      case 'in_progress':
      case 'inprogress':
        return ProjectStatus.inProgress;
      case 'completed':
        return ProjectStatus.completed;
      case 'locked':
        return ProjectStatus.locked;
      case 'unlocked':
        return ProjectStatus.unlocked;
      default:
        return ProjectStatus.unlocked;
    }
  }
}

enum ProjectDifficulty { beginner, intermediate, advanced, expert }

extension ProjectDifficultyExtension on ProjectDifficulty {
  String get displayName {
    switch (this) {
      case ProjectDifficulty.beginner:
        return 'BEGINNER';
      case ProjectDifficulty.intermediate:
        return 'INTERMEDIATE';
      case ProjectDifficulty.advanced:
        return 'ADVANCED';
      case ProjectDifficulty.expert:
        return 'EXPERT';
    }
  }

  // Parse from Supabase database values
  static ProjectDifficulty fromString(String? value) {
    if (value == null) return ProjectDifficulty.beginner;

    switch (value.toUpperCase()) {
      case 'BEGINNER':
        return ProjectDifficulty.beginner;
      case 'INTERMEDIATE':
        return ProjectDifficulty.intermediate;
      case 'ADVANCED':
        return ProjectDifficulty.advanced;
      case 'EXPERT':
        return ProjectDifficulty.expert;
      default:
        return ProjectDifficulty.beginner;
    }
  }
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
  final String? userId; // NULL = global template, UUID = user-owned project
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
    this.userId,
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

  // Helper method to parse tasks from JSONB
  static List<ProjectTask> _parseTasksFromJson(dynamic tasksData) {
    if (tasksData == null) return [];
    if (tasksData is List) {
      return tasksData
          .map((e) {
            try {
              if (e is Map<String, dynamic>) {
                return ProjectTask.fromJson(e);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<ProjectTask>()
          .toList();
    }
    return [];
  }

  // Helper method to parse resources from JSONB
  static List<String> _parseResourcesFromJson(dynamic resourcesData) {
    if (resourcesData == null) return [];
    if (resourcesData is List) {
      return resourcesData.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle both Supabase snake_case and camelCase formats
    final id = json['id'] as String;
    final title = json['title'] as String? ?? 'Untitled Project';
    final description = json['description'] as String? ?? '';
    final overview = json['overview'] as String? ?? description;

    // Handle status (Supabase doesn't have 'status' column - default to unlocked)
    final status = ProjectStatus.unlocked;

    // Handle difficulty
    final difficultyStr = json['difficulty'] as String?;
    final difficulty = ProjectDifficultyExtension.fromString(difficultyStr);

    // Handle rewards - Supabase uses xp_reward and coin_reward
    final xpReward =
        json['xp_reward'] as int? ?? json['xpReward'] as int? ?? 100;
    final coinReward =
        json['coin_reward'] as int? ?? json['coinReward'] as int? ?? 20;

    // Handle dates (Supabase uses snake_case: created_at, updated_at)
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return fallback;
        }
      }
      return fallback;
    }

    DateTime? parseDateNullable(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    final now = DateTime.now();
    final createdAt = parseDate(json['createdAt'] ?? json['created_at'], now);
    final updatedAt = parseDate(json['updatedAt'] ?? json['updated_at'], now);
    final startedAt = parseDateNullable(
      json['startedAt'] ?? json['started_at'],
    );
    final completedAt = parseDateNullable(
      json['completedAt'] ?? json['completed_at'],
    );

    return Project(
      id: id,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      title: title,
      description: description,
      overview: overview,
      status: status,
      difficulty: difficulty,
      xpReward: xpReward,
      coinReward: coinReward,
      estimatedHours:
          json['time_estimate_hours'] as int? ??
          json['estimatedHours'] as int? ??
          10,
      requiredSkills:
          (json['required_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      learningOutcomes:
          (json['learning_outcomes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['learningOutcomes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tasks: _parseTasksFromJson(json['tasks']),
      resources: _parseResourcesFromJson(json['resources']),
      submissionUrl:
          json['submissionUrl'] as String? ?? json['submission_url'] as String?,
      githubUrl: json['githubUrl'] as String? ?? json['github_url'] as String?,
      unlockLevel:
          json['unlockLevel'] as int? ?? json['unlock_level'] as int? ?? 1,
      prerequisites:
          (json['prerequisites'] as List<dynamic>?)?.cast<String>() ?? [],
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
