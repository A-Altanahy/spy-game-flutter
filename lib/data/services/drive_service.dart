import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spyfall/data/legacy/photos.dart' as photos;
import 'package:spyfall/core/config/env_config.dart';
import 'package:spyfall/data/services/download_service.dart';

class DriveService {
  // Load sensitive data from environment variables
  // These are set at compile time using --dart-define flags
  static final String driveFolder = EnvConfig.driveFolderId;
  static final String apiKey = EnvConfig.driveApiKey;

  // Singleton instance
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  // Initialize notifications - empty implementation now
  Future<void> initNotifications() async {
    // Notifications functionality removed
  }

  // Show notification - empty implementation now
  Future<void> showNotification(
      {required String title, required String body}) async {
    // Notifications functionality removed
    // Just logging the message instead
    debugPrint('Notification would have shown: $title - $body');
  }

  // Check for updates by comparing last modified time
  Future<bool> checkForUpdates() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lastUpdateTime = prefs.getString('last_update_time');

      // Get folder metadata from Google Drive
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/drive/v3/files/$driveFolder?fields=modifiedTime&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String modifiedTime = data['modifiedTime'];

        // If we have no previous update or the folder was modified, return true
        if (lastUpdateTime == null || modifiedTime != lastUpdateTime) {
          await prefs.setString('last_update_time', modifiedTime);
          return true;
        }
      } else {
        // print(
        //     'Failed to check for updates. Status code: ${response.statusCode}');
        // print('Response: ${response.body}');
      }
      return false;
    } catch (e) {
      // print('Error checking updates: $e');
      return false;
    }
  }

  // List all files/folders in the main folder
  Future<List<Map<String, dynamic>>> listFolderContents() async {
    try {
      // Build the URL for listing files in the specified folder
      final url =
          'https://www.googleapis.com/drive/v3/files?q=\'$driveFolder\'+in+parents+and+trashed=false&fields=files(id,name,mimeType)&key=$apiKey';
      // print('Listing folder contents from URL: $url');

      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
      });

      // print('Folder contents response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print('Folder contents response: ${response.body}');

        if (!data.containsKey('files')) {
          // print('Response does not contain "files" key: $data');
          return [];
        }

        final files = List<Map<String, dynamic>>.from(data['files']);
        // print(
        //     'Files found: ${files.map((f) => "${f['name']} (${f['mimeType']})").join(", ")}');
        return files;
      } else {
        // print('Failed to list folder contents: ${response.statusCode}');
        // print('Response body: ${response.body}');

        // If we get a 404, the folder ID might be incorrect
        if (response.statusCode == 404) {
          // print('Folder ID may be incorrect or not accessible');
        }
        // If we get a 403, there might be permission issues
        else if (response.statusCode == 403) {
          // print(
          //     'Permission denied. Make sure the folder is shared publicly and the API key has Drive API access');
        }
      }
      return [];
    } catch (e) {
      // print('Error listing folder contents: $e');
      return [];
    }
  }

  // List files in a specific category folder
  Future<List<Map<String, dynamic>>> listCategoryFiles(String folderId) async {
    try {
      final url =
          'https://www.googleapis.com/drive/v3/files?q=\'$folderId\'+in+parents+and+trashed=false&fields=files(id,name,mimeType)&key=$apiKey';
      // print('Listing category files from URL: $url');

      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
      });

      // print('Category files response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!data.containsKey('files')) {
          // print('Response does not contain "files" key: $data');
          return [];
        }

        final files = List<Map<String, dynamic>>.from(data['files'])
            .where((file) => file['mimeType'].toString().startsWith('image/'))
            .toList();
        // print('Found ${files.length} image files in category');
        return files;
      } else {
        // print('Failed to list category files: ${response.statusCode}');
        // print('Response body: ${response.body}');
      }
      return [];
    } catch (e) {
      // print('Error listing category files: $e');
      return [];
    }
  }

  // Download a file from Google Drive - optimized version
  Future<String?> downloadFile(
      String fileId, String fileName, String destinationFolder) async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String folderPath = '${directory.path}/$destinationFolder';

      // Create the folder if it doesn't exist
      Directory(folderPath).createSync(recursive: true);

      String filePath = '$folderPath/$fileName';

      // Use Dio for downloading with optimized settings
      final url =
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$apiKey';

      try {
        // Configure Dio with optimized settings
        final dio = Dio(BaseOptions(
          connectTimeout: Duration(seconds: 10), // Reduced from 15 to 10
          receiveTimeout: Duration(seconds: 20), // Reduced from 30 to 20
          sendTimeout: Duration(seconds: 10), // Reduced from 15 to 10
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*',
          },
          // Add these performance options
          validateStatus: (status) =>
              status! < 500, // Accept all status codes below 500
          followRedirects: true,
          maxRedirects: 5,
        ));

        // Add a download progress interceptor
        dio.interceptors
            .add(InterceptorsWrapper(onResponse: (response, handler) {
          // print('Download completed for $fileName: ${response.statusCode}');
          handler.next(response);
        }, onError: (DioException e, handler) {
          // print('Dio error for $fileName: ${e.message}');
          handler.next(e);
        }));

        // Use a faster download approach
        final response = await dio.get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: Duration(seconds: 20),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final file = File(filePath);
          await file.writeAsBytes(response.data);

          if (await file.exists() && await file.length() > 0) {
            // print(
            //     'File downloaded successfully: $filePath (${await file.length()} bytes)');
            return filePath;
          } else {
            // print(
            //     'File download verification failed: File is empty or does not exist');
            return null;
          }
        } else {
          // print('File download failed: Status ${response.statusCode}');
          return null;
        }
      } on DioException {
        // print('Dio error downloading file $fileName: ${e.message}');
        // print(
        //     'Error response: ${e.response?.statusCode} - ${e.response?.statusMessage}');
        return null;
      }
    } catch (e) {
      // print('Error downloading file $fileName: $e');
      return null;
    }
  }

  // Try a different approach - direct download with direct URL - optimized version
  Future<String?> downloadFileAlternative(
      String fileId, String fileName, String destinationFolder) async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String folderPath = '${directory.path}/$destinationFolder';

      // Create the folder if it doesn't exist
      Directory(folderPath).createSync(recursive: true);

      String filePath = '$folderPath/$fileName';

      // Try direct download URL approach for public files
      final url = 'https://drive.google.com/uc?export=download&id=$fileId';

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response =
            await client.send(request).timeout(Duration(seconds: 20));

        if (response.statusCode == 200) {
          final file = File(filePath);
          final fileStream = file.openWrite();
          await response.stream.pipe(fileStream);
          await fileStream.flush();
          await fileStream.close();

          if (await file.exists() && await file.length() > 0) {
            // print(
            //     'File downloaded successfully (alternative method): $filePath (${await file.length()} bytes)');
            return filePath;
          } else {
            // print(
            //     'Alternative download verification failed: File is empty or does not exist');
            return null;
          }
        } else {
          // print('Alternative download failed: ${response.statusCode}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // print('Error in alternative download: $e');
      return null;
    }
  }

  // Try downloading directly from Drive web interface - optimized version
  Future<String?> downloadFileWeb(
      String fileId, String fileName, String destinationFolder) async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String folderPath = '${directory.path}/$destinationFolder';

      // Create the folder if it doesn't exist
      Directory(folderPath).createSync(recursive: true);

      String filePath = '$folderPath/$fileName';

      // Use a direct Google Drive download URL - works better for public files
      final url =
          'https://drive.google.com/uc?export=download&confirm=t&id=$fileId';

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response =
            await client.send(request).timeout(Duration(seconds: 20));

        if (response.statusCode == 200) {
          final file = File(filePath);
          final fileStream = file.openWrite();
          await response.stream.pipe(fileStream);
          await fileStream.flush();
          await fileStream.close();

          if (await file.exists() && await file.length() > 0) {
            // print(
            //     'Web download complete, saved to $filePath (${await file.length()} bytes)');
            return filePath;
          } else {
            // print(
            //     'Web download verification failed: File is empty or does not exist');
            return null;
          }
        } else {
          // print('Web download failed: Status ${response.statusCode}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // print('Error in web download for $fileName: $e');
      return null;
    }
  }

  // A more robust method to check internet connectivity
  Future<bool> checkInternetConnectivity() async {
    // print('Checking internet connectivity...');

    // Try multiple sites in case one is blocked
    List<String> testUrls = [
      'https://www.google.com',
      'https://www.apple.com',
      'https://www.microsoft.com',
      'https://www.amazon.com',
      'https://www.cloudflare.com'
    ];

    for (String url in testUrls) {
      try {
        // print('Trying to connect to $url');
        final http.Client client = http.Client();
        http.Response response;

        try {
          response = await client.get(Uri.parse(url)).timeout(
            Duration(seconds: 10),
            onTimeout: () {
              // print('Connection to $url timed out');
              throw TimeoutException('Connection timed out');
            },
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            // print(
            //     'Successfully connected to $url with status code: ${response.statusCode}');
            client.close();
            return true;
          } else {
            // print(
            //     'Connected to $url but received error status code: ${response.statusCode}');
          }
        } catch (innerE) {
          // print('Error connecting to $url: $innerE');
        } finally {
          client.close();
        }
      } catch (e) {
        // print('Exception when testing $url: $e');
      }
    }

    // print(
    //     'All connectivity tests failed. Check network settings and permissions.');
    return false;
  }

  // Download all images from Google Drive - OPTIMIZED VERSION
  Future<bool> downloadAllImages(Function(double)? progressCallback) async {
    try {
      debugPrint('🚀 Starting optimized download from Google Drive');

      // List all folders at the root level
      final categoryFolders = await listFolderContents();
      debugPrint('📁 Found ${categoryFolders.length} items in root');

      // Only process folders (category folders)
      final validCategoryFolders = categoryFolders
          .where((folder) =>
              folder['mimeType'] == 'application/vnd.google-apps.folder')
          .toList();

      debugPrint('✅ Found ${validCategoryFolders.length} category folders');

      if (validCategoryFolders.isEmpty) {
        debugPrint('⚠️ No category folders found');
        return false;
      }

      // Track categories
      final categories = <Map<String, dynamic>>[];

      // Use optimized download service
      final downloadService = DownloadService();

      // Download all category images in parallel
      debugPrint('📥 Starting parallel download...');
      final downloadResult = await downloadService.downloadCategoryImages(
        categoryFolders: validCategoryFolders,
        getCategoryFiles: (categoryId) => listCategoryFiles(categoryId),
        onProgress: (progress) {
          debugPrint('📊 Progress: ${(progress * 100).toStringAsFixed(1)}%');
          if (progressCallback != null) {
            progressCallback(progress);
          }
        },
        skipIfExists:
            false, // Download all files (change to true to skip existing)
      );

      debugPrint(
          '📦 Download result: ${downloadResult.length} categories processed');

      // Build categories list
      for (var i = 0; i < validCategoryFolders.length; i++) {
        categories.add({
          'id': i + 1,
          'name': validCategoryFolders[i]['name'],
          'enabled': true,
        });
      }

      // Save categories data
      debugPrint('💾 Saving ${categories.length} categories');
      await saveCategories(categories);

      // Build images list directly from download result
      final newImages = [];

      downloadResult.forEach((categoryName, filePaths) {
        // Find category ID
        final category = categories.firstWhere(
          (c) => c['name'] == categoryName,
          orElse: () => {},
        );

        if (category.isNotEmpty) {
          final categoryId = category['id'];

          for (final filePath in filePaths) {
            final imageName = filePath.split('/').last.split('.').first;
            newImages.add({
              'icon': filePath,
              'name': imageName,
              'categoryId': categoryId,
            });
          }
        }
      });

      debugPrint(
          '🖼️ Processed ${newImages.length} images from download result');

      // Update global images list
      if (newImages.isNotEmpty) {
        photos.images = List.from(newImages);
        await photos.savePhotosData();
        debugPrint('✅ Photos data saved with ${photos.images.length} images');
      }

      // Ensure spy image is present
      await photos.ensureSpyImageInList();

      debugPrint('✅ Download and update complete!');
      return true;
    } catch (e) {
      debugPrint('❌ Error downloading images: $e');
      return false;
    }
  }

  // Update local categories and images from downloaded files
  Future<void> updateLocalData() async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String basePath = '${directory.path}/spyfall_images';

      // print('Updating local data from $basePath');

      // Exit if directory doesn't exist
      if (!Directory(basePath).existsSync()) {
        // print('Directory does not exist: $basePath');
        return;
      }

      // List all category directories
      List<FileSystemEntity> entities =
          Directory(basePath).listSync().whereType<Directory>().toList();

      // print('Found ${entities.length} category directories');

      if (entities.isEmpty) {
        // print('No category directories found');
        return;
      }

      // Create categories from directory names
      List newCategories = [];
      List newImages = [];

      // Add each category and its images
      int categoryId = 1;
      for (var entity in entities) {
        String categoryName = entity.path.split('/').last;
        // print('Processing category: $categoryName');

        // Add category
        newCategories.add({
          'name': categoryName,
          'id': categoryId,
          'enabled': true,
        });

        // Add images for this category
        List<FileSystemEntity> imageFiles = Directory(entity.path)
            .listSync()
            .where((e) =>
                e is File &&
                (e.path.endsWith('.png') ||
                    e.path.endsWith('.jpg') ||
                    e.path.endsWith('.jpeg')))
            .toList();

        // print('Found ${imageFiles.length} images in category $categoryName');

        for (var imageFile in imageFiles) {
          String imagePath = imageFile.path;
          String imageName = imagePath.split('/').last.split('.').first;

          newImages.add({
            'icon': imagePath,
            'name': imageName,
            'categoryId': categoryId,
          });
          // print('Added image: $imageName');
        }

        categoryId++;
      }

      // If we found categories and images, update the global lists
      if (newCategories.isNotEmpty) {
        // print(
        //     'Updating global categories (${newCategories.length}) and images (${newImages.length})');

        // Update the global variables
        photos.categories = List.from(newCategories);
        if (newImages.isNotEmpty) {
          photos.images = List.from(newImages);
        }

        // Save the updated data
        await photos.savePhotosData();
        // print('Data saved successfully');
      } else {
        // print('No categories found to update');
      }
    } catch (e) {
      // print('Error updating local data: $e');
    }
  }

  // Save categories to local storage
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    try {
      // print('Saving ${categories.length} categories to local storage');

      // Convert categories to JSON string
      String categoriesJson = json.encode(categories);

      // Get shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save categories
      await prefs.setString('categories', categoriesJson);

      // Update photos module categories
      photos.categories = List<Map<String, dynamic>>.from(categories);

      // print('Categories saved successfully');
    } catch (e) {
      // print('Error saving categories: $e');
    }
  }
}
