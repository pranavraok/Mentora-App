import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/models/user_model.dart';
import 'package:mentora_app/models/roadmap_node.dart';
import 'package:mentora_app/models/project.dart';
import 'package:mentora_app/models/achievement.dart';
import 'package:mentora_app/services/local_storage_service.dart';
import 'package:mentora_app/services/user_service.dart';
import 'package:mentora_app/services/roadmap_service.dart';
import 'package:mentora_app/services/project_service.dart';
import 'package:mentora_app/services/achievement_service.dart';

final storageProvider = FutureProvider<LocalStorageService>((ref) async {
  return await LocalStorageService.getInstance();
});

final userServiceProvider = Provider<UserService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return UserService(storage!);
});

final roadmapServiceProvider = Provider<RoadmapService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return RoadmapService(storage!);
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return ProjectService(storage!);
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  final storage = ref.watch(storageProvider).value;
  return AchievementService(storage!);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCurrentUser();
});

final userNotifierProvider = Provider<UserNotifier>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserNotifier(userService, ref);
});

class UserNotifier {
  final UserService _userService;
  final Ref _ref;

  UserNotifier(this._userService, this._ref);

  Future<void> updateUser(UserModel user) async {
    await _userService.updateUser(user);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> addXP(int xp) async {
    await _userService.addXP(xp);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> logout() async {
    await _userService.clearUser();
    _ref.invalidate(currentUserProvider);
  }
}

final roadmapNodesProvider = FutureProvider.family<List<RoadmapNode>, String>((ref, userId) async {
  final service = ref.watch(roadmapServiceProvider);
  return await service.getRoadmapNodes(userId);
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getProjects();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getAllAchievements();
});

final userAchievementsProvider = FutureProvider.family<List<UserAchievement>, String>((ref, userId) async {
  final service = ref.watch(achievementServiceProvider);
  return await service.getUserAchievements(userId);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
