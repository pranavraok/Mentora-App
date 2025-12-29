import 'package:flutter/foundation.dart';
import 'package:mentora_app/models/project.dart';
import 'package:mentora_app/services/local_storage_service.dart';
import 'package:mentora_app/config/supabase_config.dart';

class ProjectService {
  final LocalStorageService _storage;
  static const String _projectsKey = 'projects';

  ProjectService(this._storage);

  Future<List<Project>> getProjects() async {
    try {
      final jsonList = _storage.getJsonList(_projectsKey);
      if (jsonList.isEmpty) {
        final sample = _generateSampleProjects();
        await _saveProjects(sample);
        return sample;
      }

      return jsonList.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting projects: $e');
      return [];
    }
  }

  // 🎯 UPDATED: Add activity logging when project status changes
  Future<void> updateProject(Project project, {String? userId}) async {
    try {
      final projects = await getProjects();
      final index = projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        final oldProject = projects[index];
        projects[index] = project;
        await _saveProjects(projects);

        // 🎯 LOG ACTIVITY IF PROJECT WAS JUST COMPLETED
        if (oldProject.status != ProjectStatus.completed &&
            project.status == ProjectStatus.completed &&
            userId != null) {
          await _logProjectCompletion(userId, project);
        }

        // 🎯 LOG ACTIVITY IF ALL TASKS JUST COMPLETED
        final oldCompletedCount = oldProject.tasks.where((t) => t.isCompleted).length;
        final newCompletedCount = project.tasks.where((t) => t.isCompleted).length;

        if (project.tasks.isNotEmpty &&
            oldCompletedCount != newCompletedCount &&
            newCompletedCount == project.tasks.length &&
            userId != null) {
          await _logAllTasksCompleted(userId, project);
        }
      }
    } catch (e) {
      debugPrint('Error updating project: $e');
    }
  }

  Future<void> _saveProjects(List<Project> projects) async {
    await _storage.saveJsonList(
        _projectsKey, projects.map((p) => p.toJson()).toList());
  }

  // 🎯 NEW METHOD: Log project completion
  Future<void> _logProjectCompletion(String userId, Project project) async {
    try {
      await SupabaseConfig.client.from('user_activities').insert({
        'user_id': userId,
        'activity_type': 'project_completion',
        'title': 'Completed "${project.title}"',
        'description':
        'Finished ${project.difficulty.name} level project and earned ${project.xpReward} XP',
        'xp_earned': project.xpReward,
        'icon': 'emoji_events_rounded',
        'color': '0xFFFFD700',
        'metadata': {
          'project_id': project.id,
          'project_title': project.title,
          'difficulty': project.difficulty.name,
          'xp_reward': project.xpReward,
          'coin_reward': project.coinReward,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Logged project completion: ${project.title}');
    } catch (e) {
      debugPrint('❌ Error logging project completion: $e');
    }
  }

  // 🎯 NEW METHOD: Log all tasks completed
  Future<void> _logAllTasksCompleted(String userId, Project project) async {
    try {
      await SupabaseConfig.client.from('user_activities').insert({
        'user_id': userId,
        'activity_type': 'project_milestone',
        'title': 'All tasks done in "${project.title}"',
        'description': 'Completed all ${project.tasks.length} tasks',
        'xp_earned': 25,
        'icon': 'play_circle_rounded',
        'color': '0xFF667eea',
        'metadata': {
          'project_id': project.id,
          'tasks_count': project.tasks.length,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Logged all tasks completed: ${project.title}');
    } catch (e) {
      debugPrint('❌ Error logging tasks completion: $e');
    }
  }

  List<Project> _generateSampleProjects() {
    final now = DateTime.now();
    return [
      Project(
        id: 'proj_1',
        title: 'Personal Portfolio Website',
        description: 'Build a stunning portfolio to showcase your work',
        overview:
        'Create a responsive, modern portfolio website using HTML, CSS, and JavaScript',
        status: ProjectStatus.unlocked,
        difficulty: ProjectDifficulty.beginner,
        xpReward: 250,
        coinReward: 50,
        estimatedHours: 20,
        requiredSkills: ['HTML', 'CSS', 'JavaScript'],
        learningOutcomes: [
          'Responsive Design',
          'CSS Grid',
          'Flexbox',
          'DOM Manipulation'
        ],
        tasks: [
          ProjectTask(id: 't1', title: 'Set up project structure'),
          ProjectTask(id: 't2', title: 'Design layout and wireframe'),
          ProjectTask(id: 't3', title: 'Build header and navigation'),
          ProjectTask(id: 't4', title: 'Create about section'),
          ProjectTask(id: 't5', title: 'Add projects showcase'),
          ProjectTask(id: 't6', title: 'Implement contact form'),
          ProjectTask(id: 't7', title: 'Make it responsive'),
          ProjectTask(id: 't8', title: 'Deploy to hosting'),
        ],
        resources: [
          'MDN Web Docs',
          'CSS Tricks',
          'Frontend Mentor challenges',
        ],
        unlockLevel: 1,
        createdAt: now,
        updatedAt: now,
      ),
      Project(
        id: 'proj_2',
        title: 'Todo List App',
        description: 'Build a feature-rich todo application',
        overview: 'Create an interactive todo list with local storage persistence',
        status: ProjectStatus.locked,
        difficulty: ProjectDifficulty.beginner,
        xpReward: 200,
        coinReward: 40,
        estimatedHours: 15,
        requiredSkills: ['HTML', 'CSS', 'JavaScript'],
        learningOutcomes: ['Local Storage', 'CRUD Operations', 'Event Handling'],
        tasks: [
          ProjectTask(id: 't1', title: 'Create UI mockup'),
          ProjectTask(id: 't2', title: 'Build HTML structure'),
          ProjectTask(id: 't3', title: 'Add CSS styling'),
          ProjectTask(id: 't4', title: 'Implement add todo'),
          ProjectTask(id: 't5', title: 'Implement delete todo'),
          ProjectTask(id: 't6', title: 'Add edit functionality'),
          ProjectTask(id: 't7', title: 'Integrate local storage'),
        ],
        unlockLevel: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Project(
        id: 'proj_3',
        title: 'Weather Dashboard',
        description: 'Build a weather app using external APIs',
        overview: 'Create a beautiful weather dashboard with real-time data',
        status: ProjectStatus.locked,
        difficulty: ProjectDifficulty.intermediate,
        xpReward: 350,
        coinReward: 70,
        estimatedHours: 25,
        requiredSkills: ['JavaScript', 'APIs', 'Async/Await'],
        learningOutcomes: [
          'API Integration',
          'Promise Handling',
          'Data Visualization'
        ],
        tasks: [
          ProjectTask(id: 't1', title: 'Get API key from OpenWeatherMap'),
          ProjectTask(id: 't2', title: 'Design UI components'),
          ProjectTask(id: 't3', title: 'Fetch weather data'),
          ProjectTask(id: 't4', title: 'Display current weather'),
          ProjectTask(id: 't5', title: 'Show 5-day forecast'),
          ProjectTask(id: 't6', title: 'Add search functionality'),
          ProjectTask(id: 't7', title: 'Handle errors gracefully'),
        ],
        unlockLevel: 3,
        prerequisites: ['proj_1'],
        createdAt: now,
        updatedAt: now,
      ),
      Project(
        id: 'proj_4',
        title: 'E-commerce Product Page',
        description: 'Build an interactive product showcase',
        overview: 'Create a professional product page with cart functionality',
        status: ProjectStatus.locked,
        difficulty: ProjectDifficulty.intermediate,
        xpReward: 400,
        coinReward: 80,
        estimatedHours: 30,
        requiredSkills: ['React', 'State Management', 'CSS'],
        learningOutcomes: [
          'Component Architecture',
          'State Management',
          'User Interactions'
        ],
        unlockLevel: 5,
        createdAt: now,
        updatedAt: now,
      ),
      Project(
        id: 'proj_5',
        title: 'Full Stack Social Platform',
        description: 'Build a complete social media application',
        overview:
        'Create a full-stack app with authentication, posts, and real-time features',
        status: ProjectStatus.locked,
        difficulty: ProjectDifficulty.expert,
        xpReward: 1000,
        coinReward: 250,
        estimatedHours: 80,
        requiredSkills: ['React', 'Node.js', 'MongoDB', 'WebSockets'],
        learningOutcomes: [
          'Full Stack Development',
          'Authentication',
          'Real-time Communication'
        ],
        unlockLevel: 10,
        prerequisites: ['proj_3', 'proj_4'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
