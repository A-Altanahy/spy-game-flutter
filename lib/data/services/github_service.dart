import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spyfall/data/legacy/photos.dart' as photos;
import 'package:spyfall/main.dart' as main_app;

class GithubService {
  // Singleton instance
  static final GithubService _instance = GithubService._internal();
  factory GithubService() => _instance;
  GithubService._internal();

  // Configuration
  // TODO: User needs to update these with their actual repo details
  static const String _username = 'A-Altanahy';
  static const String _repo = 'spyfall-content';
  static const String _branch = 'main';

  // Base URLs
  String get _baseUrl =>
      'https://raw.githubusercontent.com/$_username/$_repo/$_branch';
  String get _manifestUrl => '$_baseUrl/data.json';

  final Dio _dio = Dio();

  /// Check for updates and sync content
  /// Returns true if updates were found and applied
  Future<bool> syncContent({Function(double)? onProgress}) async {
    try {
      // 1. Fetch and Cache Translations
      await fetchTranslations();

      // Load current translations for use in this sync
      final appDir = await getApplicationDocumentsDirectory();
      final String i18nPath = '${appDir.path}/spyfall_images/i18n';
      Map<String, dynamic> translations = {};
      final String currentLang = main_app.appLocaleNotifier.value.languageCode;

      try {
        final localPath = '$i18nPath/$currentLang.json';
        final file = File(localPath);
        if (await file.exists()) {
          translations = json.decode(await file.readAsString());
        }
      } catch (e) {
        // print('Error loading translations: $e');
      }

      // 2. Fetch Manifest
      // print('Fetching manifest from: $_manifestUrl');
      final response = await _dio.get(_manifestUrl);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch manifest: ${response.statusCode}');
      }

      // Parse manifest
      final Map<String, dynamic> manifest =
          json.decode(response.data.toString());
      final List<dynamic> categories = manifest['categories'] ?? [];

      // 3. Process Categories & Images
      int totalImages = 0;
      int processedImages = 0;

      // Calculate total images to download
      for (var cat in categories) {
        final List<dynamic> images = cat['images'] ?? [];
        totalImages += images.length;
      }

      if (totalImages == 0) {
        onProgress?.call(1.0);
        return false;
      }

      // Reuse appDir from above
      final String basePath = '${appDir.path}/spyfall_images';

      // 4. Download Images
      for (var cat in categories) {
        final String catId = cat['id']; // e.g., "locations"
        // Get display name from translations or fallback to ID
        final String catName = translations['categories']?[catId] ??
            catId[0].toUpperCase() + catId.substring(1);

        // Use numeric ID for internal compatibility if possible, or hash string
        // For now, we'll try to find existing ID or generate one
        int internalCatId = _getOrGenerateCategoryId(catId);

        final List<dynamic> images = cat['images'] ?? [];

        // Ensure category exists locally with the localized name
        await _ensureCategoryExists(catName, internalCatId, true);

        // Create category folder (we use the localized name for folder to match legacy behavior)
        // Ideally we should separate storage path from display name, but for now keep it simple
        final String catPath = '$basePath/$catName';
        await Directory(catPath).create(recursive: true);

        for (var img in images) {
          final String imgId = img['id']; // e.g., "beach" or "شاطئ"
          final String imgPathRelative =
              img['file']; // e.g., "content/locations/beach.jpg"

          // Encode the URL to handle Arabic characters
          final String encodedPath = Uri.encodeFull(imgPathRelative);
          final String imgUrl = '$_baseUrl/$encodedPath';

          // Get localized image name
          // If translation exists, use it.
          // If not, use the ID directly (assuming the user named the file what they want to see)
          String imgDisplayName = translations['images']?[imgId] ?? imgId;

          // Only capitalize if it looks like English (starts with ascii letter)
          if (translations['images']?[imgId] == null &&
              imgId.isNotEmpty &&
              RegExp(r'^[a-zA-Z]').hasMatch(imgId)) {
            imgDisplayName = imgId[0].toUpperCase() + imgId.substring(1);
          }

          // Determine local file name and path
          // CRITICAL: Use ID-based filename for stability across languages
          final String extension = imgPathRelative.split('.').last;
          final String localFileName = '$imgId.$extension';
          final String localFilePath = '$catPath/$localFileName';
          final File localFile = File(localFilePath);

          // Check if file exists
          if (!await localFile.exists()) {
            // Download file
            // print('Downloading: $imgUrl -> $localFilePath');
            try {
              await _dio.download(imgUrl, localFilePath);

              // Add to local photos data
              await photos.addImageToCategory(
                  localFilePath, imgDisplayName, internalCatId);
            } catch (e) {
              // print('Error downloading image $imgId: $e');
            }
          } else {
            // File exists, ensure it's in the list and UPDATE its name
            // This allows language switching to update display names

            // Find existing image entry
            final existingIndex = photos.images.indexWhere((existing) =>
                existing['icon'] == localFilePath &&
                existing['categoryId'] == internalCatId);

            if (existingIndex != -1) {
              // Update name if changed
              if (photos.images[existingIndex]['name'] != imgDisplayName) {
                photos.images[existingIndex]['name'] = imgDisplayName;
              }
            } else {
              // Add if missing from list
              await photos.addImageToCategory(
                  localFilePath, imgDisplayName, internalCatId);
            }
          }

          processedImages++;
          onProgress?.call(processedImages / totalImages);
        }
      }

      // Save all changes
      await photos.savePhotosData();

      return true;
    } catch (e) {
      // print('Error syncing content: $e');
      rethrow;
    }
  }

  /// Helper to ensure category exists in local data
  Future<void> _ensureCategoryExists(String name, int id, bool enabled) async {
    // Check if category exists by ID
    final existingIndex = photos.categories.indexWhere((c) => c['id'] == id);

    if (existingIndex == -1) {
      // Add new category
      photos.categories.add({
        'id': id,
        'name': name,
        'enabled': enabled,
      });
    } else {
      // Update existing category name if changed (e.g. translation updated)
      if (photos.categories[existingIndex]['name'] != name) {
        photos.categories[existingIndex]['name'] = name;
      }
    }
  }

  /// Generate a stable numeric ID from a string ID
  int _getOrGenerateCategoryId(String stringId) {
    // Check if we already have this category mapped in memory (not persistent across restarts but okay)
    // For better persistence, we might want to store this mapping, but for now:
    // 1. Check if any existing category has a name that matches the translation of this ID
    // This is tricky.

    // Simple approach: Hash the string ID to an int, ensuring it's positive
    // This is stable across restarts
    int hash = stringId.hashCode.abs();
    // Ensure it doesn't conflict with special ID 0 (Spy)
    if (hash == 0) hash = 1;
    return hash;
  }

  /// Fetch and cache translation files only
  Future<void> fetchTranslations() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String i18nPath = '${appDir.path}/spyfall_images/i18n';
      await Directory(i18nPath).create(recursive: true);

      // Download both languages
      for (String lang in ['ar', 'en']) {
        try {
          final String url = '$_baseUrl/i18n/$lang.json';
          final String localPath = '$i18nPath/$lang.json';

          // Download and save
          await _dio.download(url, localPath);
        } catch (e) {
          // print('Warning: Failed to fetch translation for $lang: $e');
        }
      }
    } catch (e) {
      // print('Error fetching translations: $e');
    }
  }

  /// Update repository details (helper for UI if we want to make it dynamic later)
  void updateRepoDetails(String username, String repo, String branch) {
    // This would require removing const from the fields above
  }
}
