import 'package:flutter/foundation.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/models/project.dart';

/// Supabase project service for CRUD operations with proper user ownership
class SupabaseProjectService {
  /// Create a new project for the currently logged-in user
  ///
  /// This function:
  /// 1. Gets the current authenticated user from Supabase Auth
  /// 2. Fetches the user's ID from public.users table
  /// 3. Inserts a new project with user_id set to the current user
  Future<Project?> createProjectForCurrentUser({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int xpReward,
    required int coinReward,
    required int timeEstimateHours,
    List<String> requiredSkills = const [],
    List<String> tags = const [],
    String? thumbnailUrl,
    String? bannerUrl,
  }) async {
    try {
      debugPrint(
        '[SupabaseProjectService] Creating project for current user...',
      );

      // 1. Get current auth user from Supabase
      final authUser = SupabaseConfig.client.auth.currentUser;

      if (authUser == null) {
        debugPrint('[SupabaseProjectService] ❌ No authenticated user found');
        throw Exception('User must be logged in to create projects');
      }

      debugPrint('[SupabaseProjectService] ✅ Auth user found: ${authUser.id}');

      // 2. Fetch the user's ID from public.users table using supabase_uid
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', authUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userResponse == null) {
        debugPrint(
          '[SupabaseProjectService] ❌ User profile not found in database',
        );
        throw Exception('User profile not found. Please contact support.');
      }

      final userId = userResponse['id'] as String;
      debugPrint('[SupabaseProjectService] ✅ User ID from database: $userId');

      // 3. Insert new project with user_id
      final projectData = {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'xp_reward': xpReward,
        'coin_reward': coinReward,
        'time_estimate_hours': timeEstimateHours,
        'required_skills': requiredSkills,
        'tags': tags,
        'thumbnail_url': thumbnailUrl,
        'banner_url': bannerUrl,
        'completion_count': 0,
        'trending_score': 0,
        'is_featured': false,
      };

      debugPrint('[SupabaseProjectService] 📤 Inserting project: $title');

      final response = await SupabaseConfig.client
          .from('projects')
          .insert(projectData)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[SupabaseProjectService] ✅ Project created successfully: ${response['id']}',
      );

      // Convert response to Project model
      return Project.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SupabaseProjectService] ❌ Error creating project: $e');
      rethrow;
    }
  }

  /// Clone a global template project for the current user
  ///
  /// Takes an existing project (usually with user_id = NULL) and creates a copy
  /// owned by the current user
  Future<Project?> cloneProjectForCurrentUser(String templateProjectId) async {
    try {
      debugPrint(
        '[SupabaseProjectService] Cloning project: $templateProjectId',
      );

      // 1. Fetch the template project
      final templateResponse = await SupabaseConfig.client
          .from('projects')
          .select()
          .eq('id', templateProjectId)
          .single()
          .timeout(const Duration(seconds: 10));

      final template = templateResponse as Map<String, dynamic>;

      // 2. Get current auth user
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User must be logged in to clone projects');
      }

      // 3. Fetch user's ID from database
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', authUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userResponse == null) {
        throw Exception('User profile not found');
      }

      final userId = userResponse['id'] as String;

      // 4. Create new project based on template
      final clonedData = {
        'user_id': userId,
        'title': '${template['title']} (Copy)',
        'description': template['description'],
        'category': template['category'],
        'difficulty': template['difficulty'],
        'xp_reward': template['xp_reward'],
        'coin_reward': template['coin_reward'],
        'time_estimate_hours': template['time_estimate_hours'],
        'required_skills': template['required_skills'] ?? [],
        'tags': template['tags'] ?? [],
        'thumbnail_url': template['thumbnail_url'],
        'banner_url': template['banner_url'],
        'resources': template['resources'],
        'tasks': template['tasks'],
        'completion_count': 0,
        'trending_score': 0,
        'is_featured': false,
      };

      final response = await SupabaseConfig.client
          .from('projects')
          .insert(clonedData)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[SupabaseProjectService] ✅ Project cloned: ${response['id']}',
      );

      return Project.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SupabaseProjectService] ❌ Error cloning project: $e');
      rethrow;
    }
  }

  /// Fetch all projects for the current user
  ///
  /// Returns only:
  /// - Global template projects (user_id IS NULL)
  /// - User's own projects (user_id = current_user.id)
  Future<List<Project>> fetchUserProjects() async {
    try {
      debugPrint(
        '[SupabaseProjectService] Fetching projects for current user...',
      );

      final authUser = SupabaseConfig.client.auth.currentUser;

      if (authUser == null) {
        debugPrint(
          '[SupabaseProjectService] No authenticated user - fetching only global projects',
        );
        return _fetchGlobalProjects();
      }

      final userId = authUser.id;
      debugPrint('[SupabaseProjectService] ✅ User ID: $userId');

      // Fetch projects where user_id IS NULL OR user_id = currentUser.id
      final response = await SupabaseConfig.client
          .from('projects')
          .select()
          .or('user_id.is.null,user_id.eq.$userId')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      final rows = response as List;
      debugPrint('[SupabaseProjectService] Fetched ${rows.length} projects');

      final projects = rows
          .map((row) {
            try {
              return Project.fromJson(row as Map<String, dynamic>);
            } catch (e) {
              debugPrint('[SupabaseProjectService] Error parsing project: $e');
              return null;
            }
          })
          .whereType<Project>()
          .toList();

      return projects;
    } catch (e) {
      debugPrint('[SupabaseProjectService] Error fetching projects: $e');
      rethrow;
    }
  }

  /// Fetch only global template projects (user_id IS NULL)
  Future<List<Project>> _fetchGlobalProjects() async {
    try {
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
      debugPrint('[SupabaseProjectService] Error fetching global projects: $e');
      return [];
    }
  }

  /// Update an existing project (only if owned by current user)
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('[SupabaseProjectService] Updating project: $projectId');

      // Verify current user owns this project
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User must be logged in');
      }

      // Get user's ID from database
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', authUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found');
      }

      final userId = userResponse['id'] as String;

      // Verify project belongs to user
      final projectResponse = await SupabaseConfig.client
          .from('projects')
          .select('user_id')
          .eq('id', projectId)
          .maybeSingle();

      if (projectResponse == null) {
        throw Exception('Project not found');
      }

      final projectUserId = projectResponse['user_id'] as String?;

      if (projectUserId != userId && projectUserId != null) {
        throw Exception('You do not have permission to edit this project');
      }

      // Update project
      await SupabaseConfig.client
          .from('projects')
          .update(updates)
          .eq('id', projectId)
          .timeout(const Duration(seconds: 15));

      debugPrint('[SupabaseProjectService] ✅ Project updated');
    } catch (e) {
      debugPrint('[SupabaseProjectService] ❌ Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project (only if owned by current user)
  Future<void> deleteProject(String projectId) async {
    try {
      debugPrint('[SupabaseProjectService] Deleting project: $projectId');

      // Verify current user owns this project
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User must be logged in');
      }

      // Get user's ID from database
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', authUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found');
      }

      final userId = userResponse['id'] as String;

      // Verify project belongs to user
      final projectResponse = await SupabaseConfig.client
          .from('projects')
          .select('user_id')
          .eq('id', projectId)
          .maybeSingle();

      if (projectResponse == null) {
        throw Exception('Project not found');
      }

      final projectUserId = projectResponse['user_id'] as String?;

      // Only allow deletion if user owns the project (not global templates)
      if (projectUserId != userId) {
        throw Exception('You can only delete your own projects');
      }

      // Delete project
      await SupabaseConfig.client
          .from('projects')
          .delete()
          .eq('id', projectId)
          .timeout(const Duration(seconds: 15));

      debugPrint('[SupabaseProjectService] ✅ Project deleted');
    } catch (e) {
      debugPrint('[SupabaseProjectService] ❌ Error deleting project: $e');
      rethrow;
    }
  }
}
