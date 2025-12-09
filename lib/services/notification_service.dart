// =====================================================
// NOTIFICATION SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class NotificationService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get user notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);

    return (response as List).length;
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  // Subscribe to notifications (realtime)
  RealtimeChannel subscribeToNotifications(
    String userId,
    Function(Map<String, dynamic>) onNewNotification,
  ) {
    return _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNewNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
