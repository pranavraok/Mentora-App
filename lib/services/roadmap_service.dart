import 'package:flutter/foundation.dart';
import 'package:mentora_app/models/roadmap_node.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/services/local_storage_service.dart';

class RoadmapService {
  RoadmapService(LocalStorageService localStorageService);

  // Get roadmap nodes from Supabase
  Future<List<RoadmapNode>> getRoadmapNodes(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('roadmap_nodes')
          .select()
          .eq('user_id', userId)
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => RoadmapNode.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting roadmap nodes: $e');
      return [];
    }
  }

  // Update a node in Supabase
  Future<void> updateNode(RoadmapNode node) async {
    try {
      await SupabaseConfig.client
          .from('roadmap_nodes')
          .update(node.toJson())
          .eq('id', node.id);

      debugPrint('Node updated successfully: ${node.id}');
    } catch (e) {
      debugPrint('Error updating node: $e');
    }
  }

  // Create a new node in Supabase
  Future<void> createNode(RoadmapNode node) async {
    try {
      await SupabaseConfig.client
          .from('roadmap_nodes')
          .insert(node.toJson());

      debugPrint('Node created successfully: ${node.id}');
    } catch (e) {
      debugPrint('Error creating node: $e');
    }
  }

  // Delete a node from Supabase
  Future<void> deleteNode(String nodeId) async {
    try {
      await SupabaseConfig.client
          .from('roadmap_nodes')
          .delete()
          .eq('id', nodeId);

      debugPrint('Node deleted successfully: $nodeId');
    } catch (e) {
      debugPrint('Error deleting node: $e');
    }
  }

  // Update node status
  Future<void> updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      await SupabaseConfig.client
          .from('roadmap_nodes')
          .update({
        'status': status.name,
        'started_at': status == NodeStatus.inProgress
            ? DateTime.now().toIso8601String()
            : null,
        'completed_at': status == NodeStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
      })
          .eq('id', nodeId);

      debugPrint('Node status updated: $nodeId -> ${status.name}');
    } catch (e) {
      debugPrint('Error updating node status: $e');
    }
  }

  // Update node progress
  Future<void> updateNodeProgress(String nodeId, int progressPercentage) async {
    try {
      await SupabaseConfig.client
          .from('roadmap_nodes')
          .update({
        'progress_percentage': progressPercentage,
      })
          .eq('id', nodeId);

      debugPrint('Node progress updated: $nodeId -> $progressPercentage%');
    } catch (e) {
      debugPrint('Error updating node progress: $e');
    }
  }
}
