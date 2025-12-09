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

final storageProvider = FutureProvider<LocalStorageService>((ref) async {
  return await LocalStorageService.getInstance();
});

final userServiceProvider = Provider<UserService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return UserService(storage!);
});

final roadmapServiceProvider = Provider<RoadmapService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return RoadmapService(storage!);
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return ProjectService(storage!);
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return AchievementService(storage!);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // First check if user is authenticated with Supabase
  final supabaseUser = SupabaseConfig.client.auth.currentUser;
  
  if (supabaseUser == null) {
    // Not authenticated - try to get from local storage (backwards compat)
    final userService = ref.watch(userServiceProvider);
    return await userService.getCurrentUser();
  }

  // User is authenticated with Supabase - fetch their profile from database
  try {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('supabase_uid', supabaseUser.id)
        .maybeSingle();

    if (response == null) {
      print('User profile not found in Supabase for UID: ${supabaseUser.id}');
      return null;
    }

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
  } catch (e) {
    print('Error fetching user from Supabase: $e');
    return null;
  }
});

final userNotifierProvider = Provider<UserNotifier>((ref) {
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
final roadmapNodesSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return [];

  try {
    // Get user ID from Supabase
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select('id')
        .eq('supabase_uid', currentUser.id)
        .maybeSingle();

    if (userResponse == null) return [];

    final userId = userResponse['id'] as String;

    // Fetch roadmap nodes
    final nodes = await SupabaseConfig.client
        .from('roadmap_nodes')
        .select()
        .eq('user_id', userId)
        .order('order_index', ascending: true);

    return nodes;
  } catch (e) {
    print('Error fetching roadmap nodes from Supabase: $e');
    return [];
  }
});

// =====================================================
// USER SKILLS - From Supabase
// =====================================================
final userSkillsSupabaseProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return [];

  try {
    // Get user ID from Supabase
    final userResponse = await SupabaseConfig.client
        .from('users')
        .select('id')
        .eq('supabase_uid', currentUser.id)
        .maybeSingle();

    if (userResponse == null) return [];

    final userId = userResponse['id'] as String;

    // Fetch user skills
    final skills = await SupabaseConfig.client
        .from('user_skills')
        .select()
        .eq('user_id', userId);

    return skills;
  } catch (e) {
    print('Error fetching user skills from Supabase: $e');
    return [];
  }
});

final roadmapNodesProvider = FutureProvider.family<List<RoadmapNode>, String>((ref, userId) async {
  final service = ref.watch(roadmapServiceProvider);
  return await service.getRoadmapNodes(userId);
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getProjects();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getAllAchievements();
});

final userAchievementsProvider = FutureProvider.family<List<UserAchievement>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getUserAchievements(userId);
});

final isAuthenticatedProvider = StreamProvider<bool>((ref) {
  // Listen to Supabase auth state changes
  return SupabaseConfig.client.auth.onAuthStateChange.map((data) {
    final session = data.session;
    return session != null;
  });
});
