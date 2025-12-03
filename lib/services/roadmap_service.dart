import 'package:flutter/foundation.dart';
import 'package:mentora_app/models/roadmap_node.dart';
import 'package:mentora_app/services/local_storage_service.dart';

class RoadmapService {
  final LocalStorageService _storage;
  static const String _nodesKey = 'roadmap_nodes';

  RoadmapService(this._storage);

  Future<List<RoadmapNode>> getRoadmapNodes(String userId) async {
    try {
      final jsonList = _storage.getJsonList(_nodesKey);
      if (jsonList.isEmpty) {
        final sampleNodes = _generateSampleRoadmap(userId);
        await _saveNodes(sampleNodes);
        return sampleNodes;
      }
      return jsonList.map((json) => RoadmapNode.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting roadmap nodes: $e');
      return [];
    }
  }

  Future<void> updateNode(RoadmapNode node) async {
    try {
      final nodes = await getRoadmapNodes(node.roadmapId);
      final index = nodes.indexWhere((n) => n.id == node.id);
      if (index != -1) {
        nodes[index] = node.copyWith(updatedAt: DateTime.now());
        await _saveNodes(nodes);
      }
    } catch (e) {
      debugPrint('Error updating node: $e');
    }
  }

  Future<void> _saveNodes(List<RoadmapNode> nodes) async {
    await _storage.saveJsonList(_nodesKey, nodes.map((n) => n.toJson()).toList());
  }

  List<RoadmapNode> _generateSampleRoadmap(String userId) {
    final now = DateTime.now();
    return [
      RoadmapNode(
        id: 'node_1',
        roadmapId: userId,
        title: 'Introduction to Programming',
        description: 'Learn the fundamentals of programming with Python',
        type: NodeType.course,
        status: NodeStatus.unlocked,
        xpReward: 100,
        coinReward: 20,
        estimatedHours: 20,
        skills: ['Python', 'Programming Basics'],
        resourceUrl: 'https://www.codecademy.com/learn/learn-python-3',
        providerName: 'Codecademy',
        positionX: 0.5,
        positionY: 0.1,
        region: 'Grasslands',
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_2',
        roadmapId: userId,
        title: 'Data Structures & Algorithms',
        description: 'Master essential data structures and algorithm concepts',
        type: NodeType.course,
        status: NodeStatus.locked,
        xpReward: 150,
        coinReward: 30,
        estimatedHours: 30,
        prerequisites: ['node_1'],
        skills: ['Data Structures', 'Algorithms'],
        resourceUrl: 'https://www.coursera.org/specializations/data-structures-algorithms',
        providerName: 'Coursera',
        positionX: 0.5,
        positionY: 0.25,
        region: 'Forest',
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_3',
        roadmapId: userId,
        title: 'Build a Calculator App',
        description: 'Create a functional calculator with a GUI',
        type: NodeType.project,
        status: NodeStatus.locked,
        xpReward: 200,
        coinReward: 50,
        estimatedHours: 15,
        prerequisites: ['node_1'],
        skills: ['Python', 'GUI Development'],
        positionX: 0.3,
        positionY: 0.35,
        region: 'Forest',
        order: 3,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_4',
        roadmapId: userId,
        title: 'Web Development Basics',
        description: 'Learn HTML, CSS, and JavaScript fundamentals',
        type: NodeType.course,
        status: NodeStatus.locked,
        xpReward: 120,
        coinReward: 25,
        estimatedHours: 25,
        prerequisites: ['node_2'],
        skills: ['HTML', 'CSS', 'JavaScript'],
        resourceUrl: 'https://www.freecodecamp.org/',
        providerName: 'freeCodeCamp',
        positionX: 0.5,
        positionY: 0.45,
        region: 'Mountains',
        order: 4,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_5',
        roadmapId: userId,
        title: 'Coding Challenge',
        description: 'Solve 10 intermediate coding problems',
        type: NodeType.skillCheck,
        status: NodeStatus.locked,
        xpReward: 100,
        coinReward: 30,
        estimatedHours: 10,
        prerequisites: ['node_2'],
        skills: ['Problem Solving'],
        positionX: 0.7,
        positionY: 0.5,
        region: 'Mountains',
        order: 5,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_6',
        roadmapId: userId,
        title: 'Build a Portfolio Website',
        description: 'Create your personal portfolio using modern web technologies',
        type: NodeType.project,
        status: NodeStatus.locked,
        xpReward: 300,
        coinReward: 75,
        estimatedHours: 20,
        prerequisites: ['node_4'],
        skills: ['HTML', 'CSS', 'JavaScript', 'Responsive Design'],
        positionX: 0.5,
        positionY: 0.6,
        region: 'City',
        order: 6,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_7',
        roadmapId: userId,
        title: 'Backend Development',
        description: 'Master server-side programming with Node.js',
        type: NodeType.course,
        status: NodeStatus.locked,
        xpReward: 180,
        coinReward: 40,
        estimatedHours: 35,
        prerequisites: ['node_4'],
        skills: ['Node.js', 'Express', 'APIs'],
        resourceUrl: 'https://www.udemy.com/course/nodejs-express-mongodb-bootcamp/',
        providerName: 'Udemy',
        positionX: 0.5,
        positionY: 0.75,
        region: 'City',
        order: 7,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'node_8',
        roadmapId: userId,
        title: 'Final Boss: Full Stack App',
        description: 'Build a complete full-stack application from scratch',
        type: NodeType.bossChallenge,
        status: NodeStatus.locked,
        xpReward: 500,
        coinReward: 150,
        estimatedHours: 50,
        prerequisites: ['node_6', 'node_7'],
        skills: ['Full Stack Development'],
        positionX: 0.5,
        positionY: 0.9,
        region: 'Futuristic',
        order: 8,
        createdAt: now,
        updatedAt: now,
      ),
      RoadmapNode(
        id: 'bonus_1',
        roadmapId: userId,
        title: 'Bonus: Git & GitHub Mastery',
        description: 'Learn version control with Git and collaboration on GitHub',
        type: NodeType.bonus,
        status: NodeStatus.locked,
        xpReward: 80,
        coinReward: 40,
        estimatedHours: 8,
        prerequisites: ['node_1'],
        skills: ['Git', 'GitHub'],
        resourceUrl: 'https://www.youtube.com/watch?v=RGOj5yH7evk',
        providerName: 'freeCodeCamp',
        positionX: 0.2,
        positionY: 0.2,
        region: 'Grasslands',
        order: 9,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
