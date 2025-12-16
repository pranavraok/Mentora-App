import 'package:mentora_app/models/user_model.dart';
import 'package:mentora_app/config/supabase_config.dart';

class XPService {
  /// Add XP to user and automatically handle leveling up
  static Future<Map<String, dynamic>> addXP(String userId, int xpToAdd) async {
    final supabase = SupabaseConfig.client;

    try {
      // Get current user data
      final response = await supabase
          .from('users')
          .select('xp, level')
          .eq('id', userId)
          .single();

      int currentXP = response['xp'] as int? ?? 0;
      int currentLevel = response['level'] as int? ?? 1;

      // Add new XP
      int newTotalXP = currentXP + xpToAdd;

      // Calculate new level based on total XP
      int newLevel = calculateLevelFromXP(newTotalXP);

      // Check if leveled up
      bool leveledUp = newLevel > currentLevel;

      // Update database
      await supabase.from('users').update({
        'xp': newTotalXP,
        'level': newLevel,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ XP Updated: +$xpToAdd XP | Total: $newTotalXP | Level: $currentLevel → $newLevel');

      return {
        'success': true,
        'xpAdded': xpToAdd,
        'newTotalXP': newTotalXP,
        'oldLevel': currentLevel,
        'newLevel': newLevel,
        'leveledUp': leveledUp,
      };

    } catch (e) {
      print('❌ Error adding XP: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate level from total XP
  static int calculateLevelFromXP(int totalXP) {
    int level = 1;
    int cumulativeXP = 0;

    while (true) {
      int xpRequired = UserModel.getXPRequiredForLevel(level);

      if (totalXP < cumulativeXP + xpRequired) {
        return level;
      }

      cumulativeXP += xpRequired;
      level++;

      // Safety limit (max level 100)
      if (level > 100) return 100;
    }
  }

  /// Fix existing users' levels based on their current XP
  static Future<void> fixUserLevel(String userId) async {
    final supabase = SupabaseConfig.client;

    try {
      final response = await supabase
          .from('users')
          .select('xp')
          .eq('id', userId)
          .single();

      int currentXP = response['xp'] as int? ?? 0;
      int correctLevel = calculateLevelFromXP(currentXP);

      await supabase.from('users').update({
        'level': correctLevel,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ Fixed user level: XP=$currentXP → Level=$correctLevel');

    } catch (e) {
      print('❌ Error fixing user level: $e');
    }
  }
}
