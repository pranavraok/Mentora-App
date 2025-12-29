import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mentora_app/models/user_model.dart';

import 'package:mentora_app/models/roadmap_node.dart';

import 'package:mentora_app/models/project.dart';

import 'package:mentora_app/models/achievement.dart';

import 'package:mentora_app/services/local_storage_service.dart';

import 'package:mentora_app/services/user_service.dart';

import 'package:mentora_app/services/roadmap_service.dart';

import 'package:mentora_app/services/project_service.dart';

import 'package:mentora_app/services/achievement_service.dart';

import 'package:mentora_app/config/supabase_config.dart';

final storageProvider = FutureProvider((ref) async {
  return await LocalStorageService.getInstance();
});

final userServiceProvider = Provider((ref) {
  final storage = ref.watch(storageProvider).value;
  return UserService(storage!);
});

final roadmapServiceProvider = Provider((ref) {
  final storage = ref.watch(storageProvider).value;
  return RoadmapService(storage!);
});

final projectServiceProvider = Provider((ref) {
  final storage = ref.watch(storageProvider).value;
  return ProjectService(storage!);
});

final achievementServiceProvider = Provider((ref) {
  final storage = ref.watch(storageProvider).value;
  return AchievementService(storage!);
});

// ✅ FIXED: Simple provider without auth state listener
final currentUserProvider = FutureProvider((ref) async {
  try {
    final supabaseUser = SupabaseConfig.client.auth.currentUser;

    if (supabaseUser == null) {
      debugPrint('❌ No authenticated Supabase user');
      return null;
    }

    debugPrint('✅ Authenticated user: ${supabaseUser.email}');

    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('supabase_uid', supabaseUser.id)
        .maybeSingle()
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('❌ User profile loading timed out');
        throw TimeoutException(
          'Failed to load user profile. Please check your connection.',
        );
      },
    );

    if (response == null) {
      debugPrint(
        '❌ User profile not found in Supabase for UID: ${supabaseUser.id}',
      );
      return null;
    }

    debugPrint('✅ User profile found: ${response['name']}');

    return UserModel(
      id: response['id'] as String,
      name: response['name'] as String? ?? 'User',
      email: response['email'] as String? ?? '',
      education: response['college'] as String?,
      level: response['current_level'] as int? ?? 1,
      xp: response['total_xp'] as int? ?? 0,
      coins: response['total_coins'] as int? ?? 0,
      careerGoal: response['career_goal'] as String?,
      skills: [],
      weeklyHours: 10,
      achievements: [],
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  } on TimeoutException catch (e) {
    debugPrint('❌ Timeout error: $e');
    rethrow;
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching user from Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
});

final userNotifierProvider = Provider((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserNotifier(userService, ref);
});

class UserNotifier {
  final UserService _userService;
  final Ref _ref;

  UserNotifier(this._userService, this._ref);

  Future<void> updateUser(UserModel user) async {
    await _userService.updateUser(user);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> addXP(int xp) async {
    await _userService.addXP(xp);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> logout() async {
    await _userService.clearUser();
    await SupabaseConfig.client.auth.signOut();
    _ref.invalidate(currentUserProvider);
  }
}

// =====================================================
// ROADMAP NODES - From Supabase
// =====================================================
final roadmapNodesSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>(
      (ref) async {
    debugPrint('🔍 Starting to fetch roadmap nodes...');
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;

      if (currentUser == null) {
        debugPrint('❌ No authenticated user found in Supabase');
        return [];
      }

      debugPrint('✅ Authenticated user: ${currentUser.id}');

      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', currentUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userResponse == null) {
        debugPrint(
          '❌ User not found in database for supabase_uid: ${currentUser.id}',
        );
        return [];
      }

      final userId = userResponse['id'] as String;
      debugPrint('✅ Found user in database with ID: $userId');

      final response = await SupabaseConfig.client
          .from('roadmap_nodes')
          .select()
          .eq('user_id', userId)
          .order('order_index', ascending: true)
          .timeout(const Duration(seconds: 15));

      debugPrint('✅ Fetched ${response.length} roadmap nodes from Supabase');

      final nodesList = List<Map<String, dynamic>>.from(response);

      return nodesList;
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout fetching roadmap nodes: $e');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching roadmap nodes: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  },
);

// =====================================================
// USER SKILLS - From Supabase
// =====================================================
final userSkillsSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>(
      (ref) async {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) return [];

    try {
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', currentUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userResponse == null) return [];

      final userId = userResponse['id'] as String;

      final skills = await SupabaseConfig.client
          .from('user_skills')
          .select()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(skills);
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout fetching user skills: $e');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user skills from Supabase: $e');
      return [];
    }
  },
);

final roadmapNodesProvider = FutureProvider.family<List<RoadmapNode>, String>(
      (ref, userId) async {
    final service = ref.watch(roadmapServiceProvider);
    return await service.getRoadmapNodes(userId);
  },
);

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  try {
    debugPrint('[ProjectsProvider] Fetching user projects from Supabase...');

    final currentUser = await ref.watch(currentUserProvider.future);

    if (currentUser == null) {
      debugPrint('[ProjectsProvider] ❌ No authenticated user found');
      return _fetchGlobalProjects();
    }

    final userId = currentUser.id;
    debugPrint('[ProjectsProvider] ✅ Authenticated user ID: $userId');

    final response = await SupabaseConfig.client
        .from('projects')
        .select()
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 15));

    final rows = response as List;
    debugPrint(
      '[ProjectsProvider] Fetched ${rows.length} projects for user $userId',
    );

    final projects = rows
        .map((row) {
      try {
        return Project.fromJson(row as Map<String, dynamic>);
      } catch (e) {
        debugPrint('[ProjectsProvider] Error parsing project: $e');
        return null;
      }
    })
        .whereType<Project>()
        .toList();

    // ✅ Sort by difficulty: Beginner → Intermediate → Advanced → Expert
    projects.sort((a, b) {
      const difficultyOrder = {
        ProjectDifficulty.beginner: 1,
        ProjectDifficulty.intermediate: 2,
        ProjectDifficulty.advanced: 3,
        ProjectDifficulty.expert: 4,
      };

      return (difficultyOrder[a.difficulty] ?? 999)
          .compareTo(difficultyOrder[b.difficulty] ?? 999);
    });

    debugPrint(
      '[ProjectsProvider] Successfully parsed ${projects.length} projects',
    );

    return projects;
  } catch (e) {
    debugPrint('[ProjectsProvider] Error fetching projects: $e');
    return _getDefaultProjects();
  }
});

Future<List<Project>> _fetchGlobalProjects() async {
  try {
    debugPrint(
      '[ProjectsProvider] Fetching global projects (unauthenticated)...',
    );

    final response = await SupabaseConfig.client
        .from('projects')
        .select()
        .isFilter('user_id', true)
        .timeout(const Duration(seconds: 15));

    final rows = response as List;

    final projects = rows
        .map((row) {
      try {
        return Project.fromJson(row as Map<String, dynamic>);
      } catch (e) {
        return null;
      }
    })
        .whereType<Project>()
        .toList();

    // ✅ Sort by difficulty: Beginner → Intermediate → Advanced → Expert
    projects.sort((a, b) {
      const difficultyOrder = {
        ProjectDifficulty.beginner: 1,
        ProjectDifficulty.intermediate: 2,
        ProjectDifficulty.advanced: 3,
        ProjectDifficulty.expert: 4,
      };

      return (difficultyOrder[a.difficulty] ?? 999)
          .compareTo(difficultyOrder[b.difficulty] ?? 999);
    });

    return projects;
  } catch (e) {
    debugPrint('[ProjectsProvider] Error fetching global projects: $e');
    return _getDefaultProjects();
  }
}

List<Project> _getDefaultProjects() {
  final now = DateTime.now();
  return [
    Project(
      id: 'sample_1',
      title: 'Personal Portfolio Website',
      description: 'Build a stunning portfolio to showcase your work',
      overview: 'Create a responsive portfolio website',
      status: ProjectStatus.unlocked,
      difficulty: ProjectDifficulty.beginner,
      xpReward: 250,
      coinReward: 50,
      estimatedHours: 20,
      requiredSkills: ['HTML', 'CSS', 'JavaScript'],
      learningOutcomes: ['Responsive Design'],
      unlockLevel: 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getAllAchievements();
});

final userAchievementsProvider =
FutureProvider.family<List<UserAchievement>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getUserAchievements(userId);
});


final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>(
      (ref) async {
    try {
      debugPrint('[LeaderboardProvider] Starting leaderboard fetch...');

      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .order('total_xp', ascending: false)
          .timeout(const Duration(seconds: 15));

      final rows = response as List;

      debugPrint(
        '[LeaderboardProvider] Fetched ${rows.length} total users from Supabase',
      );

      if (rows.isEmpty) {
        debugPrint('[LeaderboardProvider] No users found in database');
        return [];
      }

      final leaderboardData = rows.map((user) {
        return {
          'id': user['id'] as String? ?? '',
          'name': user['name'] as String? ?? 'Unknown',
          'college': user['college'] as String?,
          'total_xp': (user['total_xp'] as num?)?.toInt() ?? 0,
          'total_coins': (user['total_coins'] as num?)?.toInt() ?? 0,
          'streak_days': (user['streak_days'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      return leaderboardData;
    } on TimeoutException catch (e) {
      debugPrint('[LeaderboardProvider] Timeout error: $e');
      return [];
    } catch (e, st) {
      debugPrint('[LeaderboardProvider] ERROR fetching leaderboard: $e');
      debugPrint('[LeaderboardProvider] Stack trace: $st');
      rethrow;
    }
  },
);

// ❌ REMOVED: isAuthenticatedProvider - This was causing the infinite loop!
