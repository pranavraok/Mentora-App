import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/models/daily_challenge.dart';

// Daily challenge provider with real-time updates
final dailyChallengeProvider = StreamProvider.autoDispose<DailyChallenge?>((ref) {
  final client = SupabaseConfig.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return Stream.value(null);
  }

  // Get user ID from users table
  return client
      .from('users')
      .select('id')
      .eq('supabase_uid', user.id)
      .single()
      .asStream()
      .asyncExpand((userRow) {
    final userId = userRow['id'] as String;

    // Stream challenges for this user
    return client
        .from('daily_challenges')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
      if (data.isEmpty) return null;

      // Filter for non-expired challenges
      final challenge = DailyChallenge.fromJson(data.first);
      if (challenge.expiresAt.isBefore(DateTime.now())) {
        return null;
      }
      return challenge;
    });
  });
});

// Update challenge progress
final challengeProgressProvider = Provider((ref) => ChallengeProgressNotifier());

class ChallengeProgressNotifier {
  Future<void> updateProgress(String challengeId, int increment) async {
    final client = SupabaseConfig.client;

    try {
      await client.rpc('update_challenge_progress', params: {
        'p_challenge_id': challengeId,
        'p_increment': increment,
      });
    } catch (e) {
      print('Error updating challenge progress: $e');
      rethrow;
    }
  }

  Future<void> createDailyChallenge() async {
    final client = SupabaseConfig.client;
    final user = client.auth.currentUser;

    if (user == null) return;

    try {
      // Get user ID
      final userRow = await client
          .from('users')
          .select('id')
          .eq('supabase_uid', user.id)
          .single();

      final userId = userRow['id'] as String;

      // Create challenge
      await client.rpc('create_daily_challenge', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      print('Error creating daily challenge: $e');
    }
  }
}
