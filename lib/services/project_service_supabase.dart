// =====================================================
// PROJECT SERVICE - Gamified Projects
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class ProjectServiceSupabase {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get all projects
  Future<List<Map<String, dynamic>>> getAllProjects({
    String? category,
    String? difficulty,
  }) async {
    var query = _client.from('projects').select('*');

    if (category != null) query = query.eq('category', category);
    if (difficulty != null) query = query.eq('difficulty', difficulty);

    final response = await query.order('trending_score', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get user's project progress
  Future<List<Map<String, dynamic>>> getUserProjects(String userId) async {
    final response = await _client
        .from('user_project_progress')
        .select('*, projects(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Unlock project (via Edge Function - validates skills)
  Future<Map<String, dynamic>> unlockProject({
    required String userId,
    required String projectId,
  }) async {
    final response = await _client.functions.invoke(
      'unlock-project',
      body: {'user_id': userId, 'project_id': projectId},
    );

    return response.data as Map<String, dynamic>;
  }

  // Update project progress
  Future<void> updateProjectProgress({
    required String userId,
    required String projectId,
    required int progressPercentage,
    String? githubUrl,
    String? demoUrl,
  }) async {
    await _client.from('user_project_progress').upsert({
      'user_id': userId,
      'project_id': projectId,
      'progress_percentage': progressPercentage,
      'status': progressPercentage == 100 ? 'completed' : 'in_progress',
      if (githubUrl != null) 'github_url': githubUrl,
      if (demoUrl != null) 'demo_url': demoUrl,
      if (progressPercentage == 0)
        'started_at': DateTime.now().toIso8601String(),
      if (progressPercentage == 100)
        'completed_at': DateTime.now().toIso8601String(),
    });
  }

  // Complete project (via Edge Function - awards XP/coins)
  Future<Map<String, dynamic>> completeProject({
    required String userId,
    required String projectId,
    required String githubUrl,
    String? demoUrl,
  }) async {
    final response = await _client.functions.invoke(
      'complete-project',
      body: {
        'user_id': userId,
        'project_id': projectId,
        'github_url': githubUrl,
        'demo_url': demoUrl,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Get featured projects
  Future<List<Map<String, dynamic>>> getFeaturedProjects() async {
    final response = await _client
        .from('projects')
        .select('*')
        .eq('is_featured', true)
        .limit(6);

    return List<Map<String, dynamic>>.from(response);
  }
}
