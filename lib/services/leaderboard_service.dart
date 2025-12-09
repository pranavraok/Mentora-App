// =====================================================
// LEADERBOARD SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class LeaderboardService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get leaderboard (via Edge Function)
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String period = 'all_time', // 'daily', 'weekly', 'monthly', 'all_time'
    String category = 'overall', // 'overall', 'projects', 'courses', 'streak'
    int limit = 50,
  }) async {
    final response = await _client.functions.invoke(
      'leaderboard',
      body: {'period': period, 'category': category, 'limit': limit},
    );

    return List<Map<String, dynamic>>.from(response.data);
  }

  // Get user rank
  Future<Map<String, dynamic>?> getUserRank(
    String userId, {
    String period = 'all_time',
    String category = 'overall',
  }) async {
    final response = await _client
        .from('leaderboard_cache')
        .select('rank, score')
        .eq('user_id', userId)
        .eq('period', period)
        .eq('category', category)
        .maybeSingle();

    return response;
  }

  // Subscribe to leaderboard updates (realtime)
  RealtimeChannel subscribeToLeaderboard(
    String period,
    String category,
    Function(List<Map<String, dynamic>>) onUpdate,
  ) {
    return _client
        .channel('leaderboard_${period}_$category')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_cache',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'period',
            value: period,
          ),
          callback: (payload) async {
            // Refetch leaderboard when changes occur
            final leaderboard = await getLeaderboard(
              period: period,
              category: category,
            );
            onUpdate(leaderboard);
          },
        )
        .subscribe();
  }
}
