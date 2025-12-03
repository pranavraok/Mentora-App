import 'package:flutter/foundation.dart';
import 'package:mentora_app/models/user_model.dart';
import 'package:mentora_app/services/local_storage_service.dart';

class UserService {
  final LocalStorageService _storage;
  static const String _currentUserKey = 'current_user';

  UserService(this._storage);

  Future<UserModel?> getCurrentUser() async {
    try {
      final json = _storage.getJson(_currentUserKey);
      if (json == null) return null;
      return UserModel.fromJson(json);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _storage.saveJson(_currentUserKey, user.toJson());
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    await saveUser(user.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> addXP(int xp) async {
    final user = await getCurrentUser();
    if (user == null) return;

    int newXp = user.xp + xp;
    int newLevel = user.level;
    int newCoins = user.coins;

    while (newXp >= (newLevel * 100 * (1 + newLevel * 0.5)).toInt()) {
      newXp -= (newLevel * 100 * (1 + newLevel * 0.5)).toInt();
      newLevel++;
      newCoins += 50;
    }

    await updateUser(user.copyWith(
      xp: newXp,
      level: newLevel,
      coins: newCoins,
    ));
  }

  Future<void> updateStreak() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final now = DateTime.now();
    final lastLogin = user.lastLoginDate;

    if (lastLogin == null) {
      await updateUser(user.copyWith(
        streak: 1,
        lastLoginDate: now,
      ));
      return;
    }

    final daysDiff = now.difference(lastLogin).inDays;

    if (daysDiff == 1) {
      await updateUser(user.copyWith(
        streak: user.streak + 1,
        lastLoginDate: now,
      ));
    } else if (daysDiff > 1) {
      await updateUser(user.copyWith(
        streak: 1,
        lastLoginDate: now,
      ));
    }
  }

  Future<void> clearUser() async {
    await _storage.remove(_currentUserKey);
  }
}
