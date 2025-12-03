import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  Future<void> saveString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  String? getString(String key) => _preferences?.getString(key);

  Future<void> saveInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  int? getInt(String key) => _preferences?.getInt(key);

  Future<void> saveBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  bool? getBool(String key) => _preferences?.getBool(key);

  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    try {
      await _preferences?.setString(key, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving JSON for key $key: $e');
    }
  }

  Map<String, dynamic>? getJson(String key) {
    try {
      final str = _preferences?.getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading JSON for key $key: $e');
      return null;
    }
  }

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> list) async {
    try {
      await _preferences?.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving JSON list for key $key: $e');
    }
  }

  List<Map<String, dynamic>> getJsonList(String key) {
    try {
      final str = _preferences?.getString(key);
      if (str == null) return [];
      final decoded = jsonDecode(str);
      if (decoded is! List) return [];
      return List<Map<String, dynamic>>.from(
        decoded.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          debugPrint('Skipping invalid item in $key: $item');
          return null;
        }).where((item) => item != null),
      );
    } catch (e) {
      debugPrint('Error loading JSON list for key $key: $e');
      _preferences?.remove(key);
      return [];
    }
  }

  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  Future<void> clear() async {
    await _preferences?.clear();
  }
}
