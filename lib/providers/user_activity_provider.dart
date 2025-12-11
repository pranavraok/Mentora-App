import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/models/user_activity.dart';

// Recent activities provider (last 10 activities)
final recentActivitiesProvider = StreamProvider.autoDispose<List<UserActivity>>((ref) {
  final client = SupabaseConfig.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  // First get the user ID from users table
  return client
      .from('users')
      .select('id')
      .eq('supabase_uid', user.id)
      .single()
      .asStream()
      .asyncExpand((userRow) {
    final userId = userRow['id'] as String;

    return client
        .from('user_activities')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10)
        .map((data) => data.map((json) => UserActivity.fromJson(json)).toList());
  });
});

// Add activity helper
final activityLoggerProvider = Provider((ref) => ActivityLogger(ref));

class ActivityLogger {
  final Ref ref;
  ActivityLogger(this.ref);

  Future<void> logActivity({
    required String userId,
    required String activityType,
    required String title,
    String? description,
    int xpEarned = 0,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
  }) async {
    final client = SupabaseConfig.client;

    await client.from('user_activities').insert({
      'user_id': userId,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'xp_earned': xpEarned,
      'icon': icon,
      'color': color,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
