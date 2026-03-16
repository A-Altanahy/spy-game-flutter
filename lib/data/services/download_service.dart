import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spyfall/core/config/env_config.dart';

/// Optimized download service for parallel downloads
class DownloadService {
  // Singleton
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  // Reuse single Dio instance
  late final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 15),
    responseType: ResponseType.bytes,
    followRedirects: true,
    maxRedirects: 5,
    // Accept 403/429 so we can handle them manually without throwing
    validateStatus: (status) => status != null && status < 500,
  ));

  /// Maximum number of concurrent downloads
  /// Reduced to 4 to avoid Google Drive API rate limits (403/429 errors)
  static const int maxConcurrentDownloads = 4;

  /// Download a single file from Google Drive with retry logic and fallback
  Future<String?> downloadFile({
    required String fileId,
    required String fileName,
    required String destinationPath,
    bool skipIfExists = true,
    int retries = 3,
  }) async {
    final filePath = '$destinationPath/$fileName';
    final file = File(filePath);

    // Skip if file already exists and skipIfExists is true
    if (skipIfExists && await file.exists()) {
      try {
        final fileSize = await file.length();
        if (fileSize > 0) {
          // print('⏭️ Skipping existing file: $fileName');
          return filePath; // File already downloaded
        }
      } catch (e) {
        // File might be corrupted or inaccessible, redownload
      }
    }

    // print('⬇️ Downloading: $fileName from Drive...');

    // Method 1: Web Download URL (Primary - Faster & Less Rate Limited)
    final webUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

    int attempt = 0;
    while (attempt < retries) {
      try {
        attempt++;

        final response = await _dio.get(
          webUrl,
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          await file.writeAsBytes(response.data);
          if (await file.exists() && await file.length() > 0) {
            // print('✅ Downloaded: $fileName (${await file.length()} bytes)');
            return filePath;
          }
        } else if (response.statusCode == 403 || response.statusCode == 429) {
          // Rate limited - wait briefly
          // print('⚠️ Rate limited (Web) for $fileName. Waiting...');
          await Future.delayed(Duration(seconds: 1 * attempt));
          continue;
        } else {
          // print('❌ All download methods failed for $fileName'); //: Status ${response.statusCode}');
        }

        if (response.statusCode != null && response.statusCode! >= 500) {
          await Future.delayed(Duration(seconds: 1));
          continue;
        }
      } catch (e) {
        // print('❌ Fallback Download error for $fileName: $e');
        await Future.delayed(Duration(seconds: 1));
      }
    }

    // Method 2: Google Drive API (Fallback - Slower but reliable if quota allows)
    // print('🔄 Switching to fallback API method for $fileName...');
    final apiUrl =
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=${EnvConfig.driveApiKey}';

    // Try API method just once or twice as fallback
    int fallbackRetries = 2;
    attempt = 0;

    while (attempt < fallbackRetries) {
      try {
        attempt++;

        final response = await _dio.get(
          apiUrl,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          await file.writeAsBytes(response.data);

          if (await file.exists() && await file.length() > 0) {
            // print(
            //     '✅ Downloaded (Fallback): $fileName (${await file.length()} bytes)');
            return filePath;
          }
        } else if (response.statusCode == 403 || response.statusCode == 429) {
          // print('⚠️ Rate limited (API) for $fileName. Waiting...');
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }

        if (response.statusCode != null && response.statusCode! >= 500) {
          await Future.delayed(Duration(seconds: 1));
          continue;
        }
      } catch (e) {
        // print('❌ API Fallback error for $fileName: $e');
        await Future.delayed(Duration(seconds: 1));
      }
    }

    return null;
  }

  /// Download multiple files in parallel with controlled concurrency
  Future<List<String>> downloadFilesParallel({
    required List<Map<String, dynamic>> files,
    required String destinationPath,
    required Function(int)
        onFileCompleted, // Changed to report count, not percentage
    bool skipIfExists = true,
  }) async {
    final downloadedFiles = <String>[];

    // Create destination directory
    await Directory(destinationPath).create(recursive: true);

    // Process files in batches
    for (var i = 0; i < files.length; i += maxConcurrentDownloads) {
      final batch = files.skip(i).take(maxConcurrentDownloads).toList();

      // Download batch in parallel
      final batchResults = await Future.wait(
        batch.map((file) => downloadFile(
              fileId: file['id'] as String,
              fileName: file['name'] as String,
              destinationPath: destinationPath,
              skipIfExists: skipIfExists,
            )),
      );

      // Collect successful downloads
      for (var result in batchResults) {
        if (result != null) {
          downloadedFiles.add(result);
        }
        // Report completion for every file attempted, success or fail
        onFileCompleted(1);
      }
    }

    return downloadedFiles;
  }

  /// Download all category images with optimized parallel processing
  Future<Map<String, List<String>>> downloadCategoryImages({
    required List<Map<String, dynamic>> categoryFolders,
    required Future<List<Map<String, dynamic>>> Function(String)
        getCategoryFiles,
    required Function(double) onProgress,
    bool skipIfExists = true,
  }) async {
    final result = <String, List<String>>{};
    final baseDirectory = await getApplicationDocumentsDirectory();
    final basePath = '${baseDirectory.path}/spyfall_images';

    // Create base directory
    await Directory(basePath).create(recursive: true);

    var totalFiles = 0;
    var processedFiles = 0;

    // First pass: Count total files and gather file lists
    // This prevents "jumping" progress bars by knowing the true total upfront
    final categoryFilesMap = <String, List<Map<String, dynamic>>>{};

    // print('📊 Scanning categories to calculate total files...');
    for (var folder in categoryFolders) {
      final categoryId = folder['id'] as String;
      final categoryName = folder['name'] as String;

      try {
        final files = await getCategoryFiles(categoryId);
        categoryFilesMap[categoryName] = files;
        totalFiles += files.length;
      } catch (e) {
        // print('Error listing files for category $categoryName: $e');
      }
    }

    // print(
    //     '📊 Total files to download: $totalFiles across ${categoryFilesMap.length} categories');

    if (totalFiles == 0) {
      onProgress(1.0);
      return {};
    }

    // Second pass: Download files
    for (var entry in categoryFilesMap.entries) {
      final categoryName = entry.key;
      final files = entry.value;

      if (files.isEmpty) continue;

      // print('📁 Processing category: $categoryName (${files.length} files)');

      final categoryPath = '$basePath/$categoryName';

      // Prepare file info with safe names
      final filesToDownload = files.map((file) {
        final fileName = file['name'] as String;
        final safeFileName = fileName.replaceAll(' ', '_');

        return {
          'id': file['id'],
          'name': safeFileName,
        };
      }).toList();

      // Download in parallel
      final downloadedFiles = await downloadFilesParallel(
        files: filesToDownload,
        destinationPath: categoryPath,
        skipIfExists: skipIfExists,
        onFileCompleted: (count) {
          processedFiles += count;
          // Ensure progress never exceeds 1.0
          final progress = (processedFiles / totalFiles).clamp(0.0, 1.0);
          onProgress(progress);
        },
      );

      result[categoryName] = downloadedFiles;
    }

    // Ensure we report 100% at the end
    onProgress(1.0);
    return result;
  }

  /// Check if file exists and has valid size
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        return size > 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear download cache
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/spyfall_images');

      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      // print('Error clearing cache: $e');
    }
  }
}
