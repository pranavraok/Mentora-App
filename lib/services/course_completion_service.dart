import 'package:flutter/foundation.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/models/roadmap_node.dart';

class CourseCompletionService {
  // ✅ Complete a course and unlock ONLY the next one
  static Future<Map<String, dynamic>> completeCourse({
    required String nodeId,
    required String userId,
    required int xpReward,
  }) async {
    try {
      // 1. Get all nodes for this user sorted by order_index
      final nodesResponse = await SupabaseConfig.client
          .from('roadmap_nodes')
          .select()
          .eq('user_id', userId)
          .order('order_index', ascending: true);

      final allNodes = (nodesResponse as List)
          .map((json) => RoadmapNode.fromJson(json as Map<String, dynamic>))
          .toList();

      // 2. Find current node index
      final currentIndex = allNodes.indexWhere((n) => n.id == nodeId);
      if (currentIndex == -1) {
        throw Exception('Node not found');
      }

      // 3. Get user's current XP
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('total_xp')
          .eq('id', userId)
          .single();

      final currentXP = (userResponse['total_xp'] as num?)?.toInt() ?? 0;
      final newTotalXP = currentXP + xpReward;

      // 4. Mark current node as completed
      await SupabaseConfig.client.from('roadmap_nodes').update({
        'status': 'completed',
        'progress_percentage': 100,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', nodeId);

      // 5. Update user XP AND last_activity to trigger stream refresh
      await SupabaseConfig.client.from('users').update({
        'total_xp': newTotalXP,
        'last_activity': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 6. Unlock ONLY the next course (if exists and is locked)
      String? unlockedCourseTitle;
      if (currentIndex < allNodes.length - 1) {
        final nextNode = allNodes[currentIndex + 1];
        if (nextNode.status == NodeStatus.locked) {
          await SupabaseConfig.client.from('roadmap_nodes').update({
            'status': 'unlocked',
          }).eq('id', nextNode.id);
          unlockedCourseTitle = nextNode.title;
        }
      }

      debugPrint('✅ Course completed! XP: $currentXP → $newTotalXP (+$xpReward)');

      return {
        'success': true,
        'xpGained': xpReward,
        'oldXP': currentXP,
        'newTotalXP': newTotalXP,
        'unlockedCourse': unlockedCourseTitle,
      };
    } catch (e) {
      debugPrint('❌ Error completing course: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ✅ Start learning a course (change to "in_progress")
  static Future<bool> startCourse(String nodeId) async {
    try {
      await SupabaseConfig.client.from('roadmap_nodes').update({
        'status': 'inProgress',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', nodeId);

      debugPrint('✅ Course started: $nodeId');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting course: $e');
      return false;
    }
  }

  // ✅ Get user ID from Supabase auth
  static Future<String?> getUserIdFromAuth() async {
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user');
        return null;
      }

      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', currentUser.id)
          .single();

      final userId = userResponse['id'] as String;
      debugPrint('✅ User ID found: $userId');
      return userId;
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }
}
