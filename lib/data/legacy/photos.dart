import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

// Initialize with empty lists instead of default values
List categories = [];
List images = [];

// Initialize categories and images from SharedPreferences
Future<void> initPhotosData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Try to load categories
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      try {
        final decodedCategories = json.decode(categoriesJson);
        if (decodedCategories is List) {
          categories = List.from(decodedCategories);
        }
      } catch (e) {
        // print('Error decoding categories: $e');
        // Keep using the empty list that was already set
      }
    }

    // Try to load images
    final imagesJson = prefs.getString('images');
    if (imagesJson != null && imagesJson.isNotEmpty) {
      try {
        final decodedImages = json.decode(imagesJson);
        if (decodedImages is List) {
          images = List.from(decodedImages);
        }
      } catch (e) {
        // print('Error decoding images: $e');
        // Keep using the empty list that was already set
      }
    }

    // CRITICAL FIX: Always verify and refresh images from filesystem
    // This prevents stale paths and ensures files actually exist
    // Even if we loaded images from SharedPreferences, we need to validate them
    bool needsRefresh = false;

    if (images.isEmpty) {
      // No images in SharedPreferences, load from filesystem
      needsRefresh = true;
    } else {
      // Validate that image files actually exist
      // Check a sample of images (first 3) to avoid performance hit
      int samplesToCheck = images.length > 3 ? 3 : images.length;
      int invalidCount = 0;

      for (int i = 0; i < samplesToCheck; i++) {
        final imagePath = images[i]['icon']?.toString() ?? '';
        if (imagePath.isNotEmpty && !imagePath.startsWith('assets/')) {
          if (!File(imagePath).existsSync()) {
            invalidCount++;
          }
        }
      }

      // If any sample images are missing, refresh all from filesystem
      if (invalidCount > 0) {
        needsRefresh = true;
      }
    }

    if (needsRefresh) {
      final downloadedImages = await getDownloadedImages();
      if (downloadedImages.isNotEmpty) {
        images = downloadedImages;
        await savePhotosData(); // Save the refreshed images
      }
    }
  } catch (e) {
    // print('Error accessing SharedPreferences: $e');
  }
}

// Save categories and images to SharedPreferences
Future<void> savePhotosData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Save categories
    final categoriesJson = json.encode(categories);
    await prefs.setString('categories', categoriesJson);

    // Save images
    final imagesJson = json.encode(images);
    await prefs.setString('images', imagesJson);
  } catch (e) {
    // print('Error saving to SharedPreferences: $e');
  }
}

// Add a new category
Future<void> addCategory(String name) async {
  // If there are no categories, clear all images first
  if (categories.isEmpty) {
    // Clear the images list
    images.clear();
    await savePhotosData();

    // Also delete all image files from the spyfall_images directory
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String basePath = '${directory.path}/spyfall_images';
      final dir = Directory(basePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        // print('Deleted all images directory as no categories exist');
      }
    } catch (e) {
      // print('Error clearing images directory: $e');
    }
  }

  // Find the highest category ID
  int maxId = 0;
  for (var category in categories) {
    if (category['id'] > maxId) {
      maxId = category['id'];
    }
  }

  // Create a new category with ID = maxId + 1
  categories.add({
    'name': name,
    'id': maxId + 1,
    'enabled': true,
  });

  // Create the category folder
  try {
    Directory directory = await getApplicationDocumentsDirectory();
    String categoryPath = '${directory.path}/spyfall_images/$name';
    final dir = Directory(categoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      // print('Created category folder: $categoryPath');
    }
  } catch (e) {
    // print('Error creating category folder: $e');
  }

  // Save to SharedPreferences
  await savePhotosData();
}

// Delete a category and all its images
Future<void> deleteCategory(int categoryId) async {
  try {
    // Find the category index and get its name before removing it
    int categoryIndex = categories.indexWhere((cat) => cat['id'] == categoryId);
    if (categoryIndex != -1) {
      // Get the category name before removing it
      String categoryName = categories[categoryIndex]['name'] ?? '';

      // Get all images in this category before removing them
      List<Map<String, dynamic>> categoryImages = images
          .where((img) => img['categoryId'] == categoryId)
          .map((img) => Map<String, dynamic>.from(img))
          .toList();

      // Remove the category
      categories.removeAt(categoryIndex);

      // Remove all images in this category from the images list
      images.removeWhere((img) => img['categoryId'] == categoryId);

      // Delete all image files from storage
      for (var img in categoryImages) {
        if (img['icon'] != null &&
            !img['icon'].toString().startsWith('assets/')) {
          try {
            final file = File(img['icon']);
            if (await file.exists()) {
              await file.delete();
              // print('Deleted image file: ${img['icon']}');
            }
          } catch (e) {
            // print('Error deleting image file: $e');
          }
        }
      }

      // Try to delete the category folder
      if (categoryName.isNotEmpty) {
        try {
          Directory directory = await getApplicationDocumentsDirectory();
          String categoryPath =
              '${directory.path}/spyfall_images/$categoryName';
          final dir = Directory(categoryPath);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
            // print('Deleted category folder: $categoryPath');
          }
        } catch (e) {
          // print('Error deleting category folder: $e');
        }
      }

      // If this was the last category, clear all images
      if (categories.isEmpty) {
        images.clear();
        // print('Cleared all images as no categories remain');

        // Delete the entire spyfall_images directory
        try {
          Directory directory = await getApplicationDocumentsDirectory();
          String basePath = '${directory.path}/spyfall_images';
          final dir = Directory(basePath);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
            // print('Deleted entire images directory as no categories remain');
          }
        } catch (e) {
          // print('Error deleting images directory: $e');
        }
      }

      // Save to SharedPreferences
      await savePhotosData();

      // print('Successfully deleted category with ID: $categoryId and all its images');
    } else {
      // print('Category with ID $categoryId not found');
    }
  } catch (e) {
    // print('Error deleting category: $e');
  }
}

// Add an image to a category
Future<void> addImageToCategory(
    String imagePath, String name, int categoryId) async {
  images.add({
    'icon': imagePath,
    'name': name,
    'categoryId': categoryId,
  });

  // Save to SharedPreferences
  await savePhotosData();
}

// Function to check if there are downloaded images
Future<bool> hasDownloadedImages() async {
  try {
    Directory directory = await getApplicationDocumentsDirectory();
    String basePath = '${directory.path}/spyfall_images';

    // Check if directory exists and has contents
    final dir = Directory(basePath);
    if (!dir.existsSync()) {
      return false;
    }

    // Check if there are any category folders
    final entities = dir.listSync().whereType<Directory>().toList();
    if (entities.isEmpty) {
      return false;
    }

    // Check if any folder has images
    for (var entity in entities) {
      final imageFiles = Directory(entity.path)
          .listSync()
          .where((e) =>
              e is File &&
              (e.path.endsWith('.png') ||
                  e.path.endsWith('.jpg') ||
                  e.path.endsWith('.jpeg')))
          .toList();

      if (imageFiles.isNotEmpty) {
        return true;
      }
    }

    return false;
  } catch (e) {
    // print('Error checking for downloaded images: $e');
    return false;
  }
}

// Function to get image paths from downloaded files
// This function now auto-discovers categories from the filesystem
// to break the circular dependency with categories loading
Future<List<Map<String, dynamic>>> getDownloadedImages() async {
  try {
    Directory directory = await getApplicationDocumentsDirectory();
    String basePath = '${directory.path}/spyfall_images';
    List<Map<String, dynamic>> result = [];

    // Check if directory exists
    if (!Directory(basePath).existsSync()) {
      return [];
    }

    // List all category directories (skip files like spy.png in root)
    final categoryDirs =
        Directory(basePath).listSync().whereType<Directory>().toList();

    if (categoryDirs.isEmpty) {
      return [];
    }

    // Auto-discover categories from filesystem if categories list is empty
    // This ensures images can be loaded even if SharedPreferences is cleared
    Map<String, int> categoryMap = {};

    if (categories.isNotEmpty) {
      // Build map from existing categories
      for (var cat in categories) {
        categoryMap[cat['name'] as String] = cat['id'] as int;
      }
    }

    // For each category directory found on filesystem
    for (var categoryDir in categoryDirs) {
      String categoryName = categoryDir.path.split('/').last;

      // Skip the i18n directory - it contains translation files, not images
      if (categoryName == 'i18n') continue;

      // Get category ID, or create new category if it doesn't exist
      int categoryId;
      if (categoryMap.containsKey(categoryName)) {
        categoryId = categoryMap[categoryName]!;
      } else {
        // Auto-create category from filesystem folder
        // Find the highest category ID to avoid conflicts
        int maxId = 0;
        for (var cat in categories) {
          if (cat['id'] > maxId) {
            maxId = cat['id'];
          }
        }

        categoryId = maxId + 1;

        // Add to categories list
        categories.add({
          'name': categoryName,
          'id': categoryId,
          'enabled': true,
        });

        categoryMap[categoryName] = categoryId;
        // print('Auto-discovered category from filesystem: $categoryName (ID: $categoryId)');
      }

      // Get all image files in the category
      final imageFiles = categoryDir
          .listSync()
          .where((e) =>
              e is File &&
              (e.path.endsWith('.png') ||
                  e.path.endsWith('.jpg') ||
                  e.path.endsWith('.jpeg')))
          .map((e) => e as File)
          .toList();

      // Add each image to the result
      for (var imageFile in imageFiles) {
        result.add({
          'icon': imageFile.path,
          'name': imageFile.path.split('/').last.split('.').first,
          'categoryId': categoryId,
        });
      }
    }

    // Save categories if we auto-discovered any new ones
    if (categoryMap.length > categories.length - categoryMap.length) {
      await savePhotosData();
    }

    return result;
  } catch (e) {
    // print('Error getting downloaded images: $e');
    return [];
  }
}

// Function to load spy image for the game - synchronous version
ImageProvider getSpyImageProvider() {
  try {
    // First try to find the spy image in the images list
    for (var img in images) {
      if (img['name'] == 'spy') {
        File spyFile = File(img['icon']);
        if (spyFile.existsSync()) {
          // print('Found spy image in images list: ${img['icon']}');
          return FileImage(spyFile);
        }
      }
    }

    // Fallback to asset if not found in images list
    // print('Using asset spy image');
    return AssetImage('assets/images/spy.png');
  } catch (e) {
    // print('Error getting spy image: $e');
    return AssetImage('assets/images/spy.png');
  }
}

// Ensure spy image is in the images list
Future<void> ensureSpyImageInList() async {
  try {
    // Check if spy is already in the list
    bool spyExists = images.any((img) => img['name'] == 'spy');
    if (spyExists) {
      return; // Already there
    }

    // Try to find it in the spyfall_images directory
    Directory directory = await getApplicationDocumentsDirectory();
    String spyFilePath = '${directory.path}/spyfall_images/spy.png';
    File spyFile = File(spyFilePath);

    if (await spyFile.exists()) {
      // print('Found spy image at: $spyFilePath, adding to images list');

      // Add to images list
      images.add({
        'icon': spyFilePath,
        'name': 'spy',
        'categoryId': 0, // Special category for spy
      });

      // Save the updated list
      await savePhotosData();
      // print('Added spy image to images list');
    }
  } catch (e) {
    // print('Error ensuring spy image in list: $e');
  }
}

// Apply content language from cached translation files
Future<bool> applyContentLanguage(String langCode) async {
  try {
    Directory directory = await getApplicationDocumentsDirectory();
    String i18nPath = '${directory.path}/spyfall_images/i18n/$langCode.json';
    File i18nFile = File(i18nPath);

    if (!await i18nFile.exists()) {
      // print('Translation file not found for $langCode');
      return false;
    }

    // Load translations
    Map<String, dynamic> translations =
        json.decode(await i18nFile.readAsString());
    Map<String, dynamic> categoryTrans = translations['categories'] ?? {};
    Map<String, dynamic> imageTrans = translations['images'] ?? {};

    // Update Image Names
    for (var image in images) {
      String path = image['icon'] as String;
      // path is like .../spyfall_images/Locations/beach.jpg
      // or .../spyfall_images/Locations/beach.png

      String filename = path.split('/').last; // beach.jpg
      String id = filename.split('.').first; // beach

      if (imageTrans.containsKey(id)) {
        image['name'] = imageTrans[id];
      } else {
        // Fallback to capitalizing the ID if no translation
        if (RegExp(r'^[a-zA-Z]').hasMatch(id)) {
          image['name'] = id[0].toUpperCase() + id.substring(1);
        } else {
          image['name'] = id;
        }
      }
    }

    // Update Category Names
    // Since we can't easily get the ID from the category object, we'll try to match
    // based on the folder name if possible, OR we just iterate through all translations
    // and see if we can find a match? No that's inefficient.
    // This is a problem. If we change the language, the folder name on disk is still the OLD language.
    // This means we can't easily rename the folder without moving files.
    //
    // BUT, the user just wants the DISPLAY name to change.
    // The 'name' field in the category object is what's displayed.
    //
    // If we can't map back to the ID, we can't translate the category name.
    //
    // WORKAROUND: We will iterate through all categories in the translation file.
    // We will check if we have a category that matches the *current* name? No, that changes.
    //
    // We need to store the original string ID.
    // Let's update GithubService to store 'originalId' in the category object.
    // But first, let's implement what we can (Images) and then fix Categories.

    // Actually, let's just update the images for now as that's the bulk of the content.
    // For categories, we might need to rely on a "best effort" or update the data structure.
    //
    // Let's check if we can add 'originalId' to the category object in GithubService.
    // Yes, we can.

    // For now, I will implement the image update logic which is robust due to the filename change.
    // And I will add a TODO for categories or try to match by ID if we can.
    //
    // Wait, `_getOrGenerateCategoryId` uses `hashCode`.
    // If we iterate through the translation keys (which are the IDs), we can compute the hash
    // and see if it matches any category ID!

    Map<int, String> idToTrans = {};
    categoryTrans.forEach((key, value) {
      // We need to replicate the hash logic from GithubService
      int hash = key.hashCode.abs();
      if (hash == 0) hash = 1;
      idToTrans[hash] = value as String;
    });

    for (var category in categories) {
      int id = category['id'] as int;
      if (idToTrans.containsKey(id)) {
        category['name'] = idToTrans[id];
      }
    }

    await savePhotosData();
    return true;
  } catch (e) {
    // print('Error applying content language: $e');
    return false;
  }
}
