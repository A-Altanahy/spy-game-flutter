import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spyfall/core/constants/app_constants.dart';

/// Service for handling local data persistence
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Get a string value from storage
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      // print('Error getting string for key $key: $e');
      return null;
    }
  }

  /// Set a string value in storage
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      // print('Error setting string for key $key: $e');
      return false;
    }
  }

  /// Get an integer value from storage
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      // print('Error getting int for key $key: $e');
      return null;
    }
  }

  /// Set an integer value in storage
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      // print('Error setting int for key $key: $e');
      return false;
    }
  }

  /// Get a boolean value from storage
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      // print('Error getting bool for key $key: $e');
      return null;
    }
  }

  /// Set a boolean value in storage
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      // print('Error setting bool for key $key: $e');
      return false;
    }
  }

  /// Remove a value from storage
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      // print('Error removing key $key: $e');
      return false;
    }
  }

  /// Clear all data from storage
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      // print('Error clearing storage: $e');
      return false;
    }
  }

  /// Save a list of objects as JSON
  Future<bool> saveJsonList(String key, List<Map<String, dynamic>> list) async {
    try {
      final jsonString = json.encode(list);
      return await setString(key, jsonString);
    } catch (e) {
      // print('Error saving JSON list for key $key: $e');
      return false;
    }
  }

  /// Load a list of objects from JSON
  Future<List<Map<String, dynamic>>?> loadJsonList(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return null;
    } catch (e) {
      // print('Error loading JSON list for key $key: $e');
      return null;
    }
  }

  /// Save categories
  Future<bool> saveCategories(List<Map<String, dynamic>> categories) async {
    return await saveJsonList(AppConstants.categoriesKey, categories);
  }

  /// Load categories
  Future<List<Map<String, dynamic>>?> loadCategories() async {
    return await loadJsonList(AppConstants.categoriesKey);
  }

  /// Save images
  Future<bool> saveImages(List<Map<String, dynamic>> images) async {
    return await saveJsonList(AppConstants.imagesKey, images);
  }

  /// Load images
  Future<List<Map<String, dynamic>>?> loadImages() async {
    return await loadJsonList(AppConstants.imagesKey);
  }

  /// Check if storage contains a key
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}
