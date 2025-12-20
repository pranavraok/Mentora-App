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

// ✅ FIXED: Added timeout and better error handling
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  try {
    // First check if user is authenticated with Supabase
    final supabaseUser = SupabaseConfig.client.auth.currentUser;

    if (supabaseUser == null) {
      debugPrint('❌ No authenticated Supabase user');
      // Not authenticated - try to get from local storage (backwards compat)
      final userService = ref.watch(userServiceProvider);
      return await userService.getCurrentUser();
    }

    debugPrint('✅ Authenticated user: ${supabaseUser.email}');

    // User is authenticated with Supabase - fetch their profile from database with timeout
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

    // Convert Supabase user data to UserModel
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
    rethrow; // Re-throw timeout to be handled by UI
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching user from Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow; // Re-throw to show error UI
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
    _ref.invalidate(currentUserProvider);
  }
}

// =====================================================
// ROADMAP NODES - From Supabase
// =====================================================

final roadmapNodesSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  debugPrint('🔍 Starting to fetch roadmap nodes...');
  try {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No authenticated user found in Supabase');
      return [];
    }

    debugPrint('✅ Authenticated user: ${currentUser.id}');

    // Get user ID from Supabase users table with timeout
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

    // Fetch roadmap nodes with timeout
    final response = await SupabaseConfig.client
        .from('roadmap_nodes')
        .select()
        .eq('user_id', userId)
        .order('order_index', ascending: true)
        .timeout(const Duration(seconds: 15));

    debugPrint('✅ Raw response from Supabase: $response');
    debugPrint('✅ Response type: ${response.runtimeType}');
    debugPrint('✅ Fetched ${response.length} roadmap nodes from Supabase');

    // Print first node for debugging
    if (response.isNotEmpty) {
      debugPrint('📋 First node sample:');
      debugPrint('   Title: ${response[0]['title']}');
      debugPrint('   Type: ${response[0]['node_type']}');
      debugPrint('   Status: ${response[0]['status']}');
    } else {
      debugPrint('⚠️ No nodes found for user: $userId');
    }

    // Convert to List<Map<String, dynamic>>
    final nodesList = List<Map<String, dynamic>>.from(response);
    debugPrint(
      '✅ Converted to List<Map<String, dynamic>> with ${nodesList.length} items',
    );
    return nodesList;
  } on TimeoutException catch (e) {
    debugPrint('❌ Timeout fetching roadmap nodes: $e');
    return [];
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching roadmap nodes: $e');
    debugPrint('Stack trace: $stackTrace');
    return [];
  }
});

// =====================================================
// USER SKILLS - From Supabase
// =====================================================

final userSkillsSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return [];

  try {
    // Get user ID from Supabase
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select('id')
        .eq('supabase_uid', currentUser.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (userResponse == null) return [];

    final userId = userResponse['id'] as String;

    // Fetch user skills with timeout
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
});

final roadmapNodesProvider = FutureProvider.family<List<RoadmapNode>, String>((
  ref,
  userId,
) async {
  final service = ref.watch(roadmapServiceProvider);
  return await service.getRoadmapNodes(userId);
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  try {
    debugPrint('[ProjectsProvider] Fetching user projects from Supabase...');

    // Get current authenticated user
    final currentUser = SupabaseConfig.client.auth.currentUser;

    if (currentUser == null) {
      debugPrint('[ProjectsProvider] ❌ No authenticated user found');
      // Still fetch global projects (user_id IS NULL) for unauthenticated users
      return _fetchGlobalProjects();
    }

    final userId = currentUser.id;
    debugPrint('[ProjectsProvider] ✅ Authenticated user ID: $userId');

    // Fetch projects that are either:
    // 1. Global templates (user_id IS NULL) - visible to all users
    // 2. User's own projects (user_id = current_user.id)
    final response = await SupabaseConfig.client
        .from('projects')
        .select()
        .or('user_id.is.null,user_id.eq.$userId')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 15));

    final rows = response as List;
    debugPrint(
      '[ProjectsProvider] Fetched ${rows.length} projects for user $userId',
    );

    // Convert to Project models
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

    debugPrint(
      '[ProjectsProvider] Successfully parsed ${projects.length} projects',
    );
    return projects;
  } catch (e) {
    debugPrint('[ProjectsProvider] Error fetching projects: $e');
    return _getDefaultProjects();
  }
});

/// Fetch only global template projects (user_id IS NULL)
Future<List<Project>> _fetchGlobalProjects() async {
  try {
    debugPrint(
      '[ProjectsProvider] Fetching global projects (unauthenticated)...',
    );

    final response = await SupabaseConfig.client
        .from('projects')
        .select()
        .isFilter('user_id', true) // user_id IS NULL
        .order('created_at', ascending: false)
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

    return projects;
  } catch (e) {
    debugPrint('[ProjectsProvider] Error fetching global projects: $e');
    return _getDefaultProjects();
  }
}

/// Default fallback projects
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

// NOTE: Leaderboard data from Supabase ordered by XP DESC
// Fetches ALL users with proper error handling and data validation
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    debugPrint('[LeaderboardProvider] Starting leaderboard fetch...');

    // Direct query to get all users without any restrictions with timeout
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .order('total_xp', ascending: false)
        .timeout(const Duration(seconds: 15));

    debugPrint(
      '[LeaderboardProvider] Raw response type: ${response.runtimeType}',
    );

    final rows = response as List;
    debugPrint(
      '[LeaderboardProvider] Fetched ${rows.length} total users from Supabase',
    );

    // Print ALL rows
    for (var row in rows) {
      debugPrint('[LeaderboardProvider] Raw row: $row');
    }

    if (rows.isEmpty) {
      debugPrint('[LeaderboardProvider] No users found in database');
      return [];
    }

    // Ensure all required fields are present with defaults
    final leaderboardData = rows.map((user) {
      debugPrint(
        '[LeaderboardProvider] Processing user: ${user['name']} with XP: ${user['total_xp']}',
      );
      return {
        'id': user['id'] as String? ?? '',
        'name': user['name'] as String? ?? 'Unknown',
        'college': user['college'] as String?,
        'total_xp': (user['total_xp'] as num?)?.toInt() ?? 0,
        'total_coins': (user['total_coins'] as num?)?.toInt() ?? 0,
        'streak_days': (user['streak_days'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    debugPrint(
      '[LeaderboardProvider] Transformed ${leaderboardData.length} users for display',
    );
    debugPrint(
      '[LeaderboardProvider] Top user: ${leaderboardData.isNotEmpty ? leaderboardData[0]['name'] : 'N/A'} with ${leaderboardData.isNotEmpty ? leaderboardData[0]['total_xp'] : 0} XP',
    );

    return leaderboardData;
  } on TimeoutException catch (e) {
    debugPrint('[LeaderboardProvider] Timeout error: $e');
    return [];
  } catch (e, st) {
    debugPrint('[LeaderboardProvider] ERROR fetching leaderboard: $e');
    debugPrint('[LeaderboardProvider] Stack trace: $st');
    rethrow;
  }
});

// Stream provider for real-time auth state changes
final isAuthenticatedProvider = StreamProvider<bool>((ref) {
  // Listen to Supabase auth state changes
  return SupabaseConfig.client.auth.onAuthStateChange.map((data) {
    final session = data.session;
    final isSignedIn = session != null;
    debugPrint(
      'Auth state changed: ${isSignedIn ? "signed in" : "signed out"}',
    );

    // Invalidate user provider when auth state changes
    if (!isSignedIn) {
      ref.invalidate(currentUserProvider);
    }

    return isSignedIn;
  });
});
