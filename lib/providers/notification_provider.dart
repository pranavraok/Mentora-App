import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/models/notification.dart';

// Real-time notifications stream
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final client = SupabaseConfig.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  return client
      .from('users')
      .select('id')
      .eq('supabase_uid', user.id)
      .single()
      .asStream()
      .asyncExpand((userRow) {
    final userId = userRow['id'] as String;

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  });
});

// Unread count
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);

  return notificationsAsync.when(
    data: (notifications) {
      return Stream.value(notifications.where((n) => !n.isRead).length);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

// Notification actions
final notificationActionsProvider = Provider((ref) => NotificationActions());

class NotificationActions {
  final _supabase = SupabaseConfig.client;

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase.from('notifications').delete().eq('id', notificationId);
  }
}
