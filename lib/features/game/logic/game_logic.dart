import 'dart:math';
import 'dart:io';
import 'package:spyfall/data/models/category.dart';
import 'package:spyfall/data/models/game_image.dart';
import 'package:spyfall/data/models/game_settings.dart';

/// Contains all game-related business logic
class GameLogic {
  // Use cryptographically secure random number generation
  static final Random _random = Random.secure();

  /// Generate list of player roles (spies and regular players)
  static List<String> generatePlayerRoles(GameSettings settings) {
    final roles = List.generate(
          settings.playerCount - settings.spyCount,
          (_) => "صالح",
        ) +
        List.generate(settings.spyCount, (_) => "جاسوس");

    roles.shuffle(_random);
    return roles;
  }

  /// Select a random location from enabled categories
  static Future<GameImage?> selectRandomLocation(
    List<Category> categories,
    List<GameImage> images,
  ) async {
    try {
      // Get enabled category IDs
      final enabledCategoryIds =
          categories.where((cat) => cat.enabled).map((cat) => cat.id).toList();

      if (enabledCategoryIds.isEmpty) {
        // print('No enabled categories found');
        return null;
      }

      // Get images from enabled categories
      final enabledImages = images
          .where((img) => enabledCategoryIds.contains(img.categoryId))
          .toList();

      if (enabledImages.isEmpty) {
        // print('No images found in enabled categories');
        return null;
      }

      // Filter to only valid (existing) images
      final validImages = <GameImage>[];
      for (var img in enabledImages) {
        if (img.isAsset) {
          validImages.add(img);
        } else {
          // Check if file exists
          try {
            final file = File(img.iconPath);
            if (file.existsSync()) {
              validImages.add(img);
            } else {
              // print('Image file does not exist: ${img.iconPath}');
            }
          } catch (e) {
            // print('Error checking file existence: $e');
          }
        }
      }

      if (validImages.isEmpty) {
        // print('No valid images found');
        return null;
      }

      // Select random image
      final randomIndex = _random.nextInt(validImages.length);
      final selectedImage = validImages[randomIndex];

      // print(
      //     'Selected image: ${selectedImage.name} with path: ${selectedImage.iconPath}');
      return selectedImage;
    } catch (e) {
      // print('Error selecting random location: $e');
      return null;
    }
  }

  /// Validate if game can start
  static Future<GameValidationResult> validateGameStart(
    GameSettings settings,
    List<Category> categories,
    List<GameImage> images,
  ) async {
    // Validate player and spy counts
    if (!settings.isValid) {
      return GameValidationResult(
        isValid: false,
        errorMessage: settings.validationError,
      );
    }

    // Check if any categories are enabled
    final hasEnabledCategories = categories.any((cat) => cat.enabled);
    if (!hasEnabledCategories) {
      return GameValidationResult(
        isValid: false,
        errorMessage: 'لا توجد فئات مفعلة',
        showCategoryDialog: true,
      );
    }

    // Get enabled category IDs
    final enabledCategoryIds =
        categories.where((cat) => cat.enabled).map((cat) => cat.id).toList();

    // Check if enabled categories have accessible images
    final validImages = <GameImage>[];
    final categoriesWithoutImages = <Category>[];
    final categoriesWithInaccessibleImages = <Category, List<String>>{};

    for (var categoryId in enabledCategoryIds) {
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      final categoryImages =
          images.where((img) => img.categoryId == categoryId).toList();

      if (categoryImages.isEmpty) {
        categoriesWithoutImages.add(category);
        continue;
      }

      // Check if images are accessible
      bool hasAccessibleImages = false;
      final inaccessiblePaths = <String>[];

      for (var img in categoryImages) {
        if (img.isAsset) {
          hasAccessibleImages = true;
          validImages.add(img);
          break;
        } else {
          try {
            final file = File(img.iconPath);
            if (file.existsSync()) {
              hasAccessibleImages = true;
              validImages.add(img);
              break;
            } else {
              inaccessiblePaths.add(img.iconPath);
            }
          } catch (e) {
            // print('Error checking file: $e');
            inaccessiblePaths.add(img.iconPath);
          }
        }
      }

      if (!hasAccessibleImages) {
        categoriesWithInaccessibleImages[category] = inaccessiblePaths;
      }
    }

    if (validImages.isEmpty) {
      return GameValidationResult(
        isValid: false,
        errorMessage: 'لا توجد صور متاحة في الفئات المفعلة',
        showCategoryDialog: true,
        categoriesWithoutImages: categoriesWithoutImages,
        categoriesWithInaccessibleImages: categoriesWithInaccessibleImages,
      );
    }

    return GameValidationResult(isValid: true);
  }

  /// Get default fallback location
  static GameImage getDefaultLocation() {
    return const GameImage(
      iconPath: 'assets/images/spy.png',
      name: 'المكان',
      categoryId: 0,
    );
  }
}

/// Result of game validation
class GameValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool showCategoryDialog;
  final List<Category> categoriesWithoutImages;
  final Map<Category, List<String>> categoriesWithInaccessibleImages;

  GameValidationResult({
    required this.isValid,
    this.errorMessage,
    this.showCategoryDialog = false,
    this.categoriesWithoutImages = const [],
    this.categoriesWithInaccessibleImages = const {},
  });
}
