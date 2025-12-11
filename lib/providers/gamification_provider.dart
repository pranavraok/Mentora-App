import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/config/supabase_config.dart';

/// Gamification state model
class GamificationState {
  final int totalXp;
  final int totalCoins;
  final int streakDays;
  final int achievementCount;

  const GamificationState({
    this.totalXp = 0,
    this.totalCoins = 0,
    this.streakDays = 0,
    this.achievementCount = 0,
  });

  GamificationState copyWith({
    int? totalXp,
    int? totalCoins,
    int? streakDays,
    int? achievementCount,
  }) {
    return GamificationState(
      totalXp: totalXp ?? this.totalXp,
      totalCoins: totalCoins ?? this.totalCoins,
      streakDays: streakDays ?? this.streakDays,
      achievementCount: achievementCount ?? this.achievementCount,
    );
  }
}

/// Provider for gamification data
/// Fetches current user's XP, coins, streak, and achievements
final gamificationProvider = FutureProvider<GamificationState>((ref) async {
  final supabase = SupabaseConfig.client;
  final sessionUser = supabase.auth.currentUser;

  if (sessionUser == null) {
    throw Exception('User not authenticated');
  }

  // Fetch user profile with gamification data
  final userRow = await supabase
      .from('users')
      .select('id, total_xp, total_coins, streak_days')
      .eq('supabase_uid', sessionUser.id)
      .single();

  final userId = userRow['id'] as String;
  final totalXp = (userRow['total_xp'] as num?)?.toInt() ?? 0;
  final totalCoins = (userRow['total_coins'] as num?)?.toInt() ?? 0;
  final streakDays = (userRow['streak_days'] as num?)?.toInt() ?? 0;

  // Count achievements for current user
  final achievementRows = await supabase
      .from('achievements')
      .select('id')
      .eq('user_id', userId);

  return GamificationState(
    totalXp: totalXp,
    totalCoins: totalCoins,
    streakDays: streakDays,
    achievementCount: achievementRows.length,
  );
});
