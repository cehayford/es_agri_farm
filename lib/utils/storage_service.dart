import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Initialize storage (call this in main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // Save string data
  static Future<bool> saveString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  // Get string data
  static String? getString(String key) {
    return _preferences.getString(key);
  }

  // Save boolean data
  static Future<bool> saveBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  // Get boolean data
  static bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  // Save integer data
  static Future<bool> saveInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  // Get integer data
  static int? getInt(String key) {
    return _preferences.getInt(key);
  }

  // Save user data as JSON
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    return await saveString(AppConstants.userDataKey, jsonString);
  }

  // Get user data from JSON
  static Map<String, dynamic>? getUserData() {
    final jsonString = getString(AppConstants.userDataKey);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Save user token
  static Future<bool> saveUserToken(String token) async {
    return await saveString(AppConstants.userTokenKey, token);
  }

  // Get user token
  static String? getUserToken() {
    return getString(AppConstants.userTokenKey);
  }

  // Check if first time user
  static bool isFirstTime() {
    return getBool(AppConstants.isFirstTimeKey) ?? true;
  }

  // Set first time to false
  static Future<bool> setNotFirstTime() async {
    return await saveBool(AppConstants.isFirstTimeKey, false);
  }

  // Remove specific data
  static Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  // Clear all user data (for logout)
  static Future<void> clearUserData() async {
    await remove(AppConstants.userTokenKey);
    await remove(AppConstants.userDataKey);
  }

  // Clear all data
  static Future<bool> clearAll() async {
    return await _preferences.clear();
  }
}
