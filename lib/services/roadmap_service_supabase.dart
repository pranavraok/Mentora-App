// =====================================================
// ROADMAP SERVICE - AI-Generated Career Roadmaps
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class RoadmapService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Generate roadmap via Gemini (Edge Function)
  Future<Map<String, dynamic>> generateRoadmap({
    required String userId,
    required String careerGoal,
    required List<String> currentSkills,
    required List<String> targetSkills,
    String? experience,
    String? education,
    String? learningStyle,
    int? timelineMonths,
  }) async {
    final response = await _client.functions.invoke(
      'generate-roadmap',
      body: {
        'user_profile': {
          'career_goal': careerGoal,
          'current_skills': currentSkills.map((skill) => {
            'skill': skill,
            'level': 'Beginner'
          }).toList(),
          'target_skills': targetSkills.map((skill) => {
            'skill': skill,
            'level': 'Advanced'
          }).toList(),
          'interests': targetSkills,
          'timeline_months': timelineMonths ?? 12,
          'learning_style': learningStyle ?? 'Visual',
          'college': education,
        },
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Get user's roadmap
  Future<List<Map<String, dynamic>>> getUserRoadmap(String userId) async {
    final response = await _client
        .from('roadmap_nodes')
        .select('*')
        .eq('user_id', userId)
        .order('order_index', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update node status
  Future<void> updateNodeStatus({
    required String nodeId,
    required String status, // 'locked', 'unlocked', 'in_progress', 'completed'
    int? progressPercentage,
  }) async {
    await _client
        .from('roadmap_nodes')
        .update({
          'status': status,
          if (progressPercentage != null)
            'progress_percentage': progressPercentage,
          if (status == 'completed')
            'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', nodeId);
  }

  // Get nodes by status
  Future<List<Map<String, dynamic>>> getNodesByStatus(
    String userId,
    String status,
  ) async {
    final response = await _client
        .from('roadmap_nodes')
        .select('*')
        .eq('user_id', userId)
        .eq('status', status)
        .order('order_index', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Subscribe to roadmap updates (realtime)
  RealtimeChannel subscribeToRoadmap(
    String userId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    return _client
        .channel('roadmap_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'roadmap_nodes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onUpdate(payload.newRecord);
            }
          },
        )
        .subscribe();
  }
}
