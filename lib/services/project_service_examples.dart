// =====================================================
// EXAMPLE: How to use SupabaseProjectService
// =====================================================

// 1. CREATE A NEW PROJECT FOR CURRENT USER
// ============================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mentora_app/services/supabase_project_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';

Future<void> createNewProject() async {
  final service = SupabaseProjectService();

  try {
    final project = await service.createProjectForCurrentUser(
      title: 'My Flutter App',
      description: 'A beautiful cross-platform mobile app',
      category: 'Mobile Development',
      difficulty: 'INTERMEDIATE',
      xpReward: 300,
      coinReward: 60,
      timeEstimateHours: 25,
      requiredSkills: ['Flutter', 'Dart', 'Firebase'],
      tags: ['mobile', 'flutter', 'ios', 'android'],
      thumbnailUrl: 'https://example.com/thumb.png',
      bannerUrl: 'https://example.com/banner.png',
    );

    //print('✅ Project created: ${project!.title}');
  } catch (e) {
    //print('❌ Failed to create project: $e');
  }
}

// 2. CLONE A GLOBAL TEMPLATE PROJECT
// ====================================
Future<void> cloneTemplateProject(String templateId) async {
  final service = SupabaseProjectService();

  try {
    final clonedProject = await service.cloneProjectForCurrentUser(templateId);
    print('✅ Template cloned: ${clonedProject!.title}');
  } catch (e) {
    print('❌ Failed to clone template: $e');
  }
}

// 3. FETCH USER'S PROJECTS (Global + Own)
// ========================================
Future<void> loadUserProjects() async {
  final service = SupabaseProjectService();

  try {
    final projects = await service.fetchUserProjects();
    print('✅ Loaded ${projects.length} projects');

    for (var project in projects) {
      print('  - ${project.title} (${project.difficulty.displayName})');
    }
  } catch (e) {
    print('❌ Failed to load projects: $e');
  }
}

// 4. UPDATE A PROJECT (if you own it)
// ====================================
Future<void> updateMyProject(String projectId) async {
  final service = SupabaseProjectService();

  try {
    await service.updateProject(projectId, {
      'title': 'Updated Title',
      'description': 'Updated description',
      'xp_reward': 400,
    });
    print('✅ Project updated');
  } catch (e) {
    print('❌ Failed to update project: $e');
  }
}

// 5. DELETE A PROJECT (only own projects)
// ========================================
Future<void> deleteMyProject(String projectId) async {
  final service = SupabaseProjectService();

  try {
    await service.deleteProject(projectId);
    print('✅ Project deleted');
  } catch (e) {
    print('❌ Failed to delete project: $e');
  }
}

// 6. USE IN A FLUTTER WIDGET WITH RIVERPOD
// ==========================================

final supabaseProjectServiceProvider = Provider((ref) {
  return SupabaseProjectService();
});

final userProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final service = ref.watch(supabaseProjectServiceProvider);
  return await service.fetchUserProjects();
});

// In your widget:
class ProjectsListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(userProjectsProvider);

    return projectsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (projects) => ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ListTile(
            title: Text(project.title),
            subtitle: Text(project.description),
          );
        },
      ),
    );
  }
}
