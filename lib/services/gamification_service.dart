// =====================================================
// GAMIFICATION SERVICE - XP, Levels, Achievements
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class GamificationService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Award XP (via Edge Function)
  Future<Map<String, dynamic>> awardXP({
    required String userId,
    required int amount,
    required String reason,
    required String source, // 'project', 'course', 'daily', 'achievement'
  }) async {
    final response = await _client.functions.invoke(
      'award-xp',
      body: {
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'source': source,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Get user stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final response = await _client
        .from('users')
        .select('current_level, total_xp, total_coins, streak_days')
        .eq('id', userId)
        .single();

    return response;
  }

  // Get XP history
  Future<List<Map<String, dynamic>>> getXPHistory(String userId) async {
    final response = await _client
        .from('xp_history')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    final response = await _client
        .from('achievements')
        .select('*')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Claim daily reward
  Future<Map<String, dynamic>> claimDailyReward(String userId) async {
    final response = await _client.functions.invoke(
      'daily-rewards',
      body: {'user_id': userId},
    );

    return response.data as Map<String, dynamic>;
  }

  // Calculate XP needed for next level
  int xpForNextLevel(int currentLevel) {
    return ((currentLevel * currentLevel) * 1000);
  }

  // Subscribe to XP changes (realtime)
  RealtimeChannel subscribeToXPUpdates(
    String userId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    return _client
        .channel('xp_updates_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
}
