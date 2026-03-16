import 'dart:io';
import 'package:flutter/foundation.dart';

/// Represents an image used in the game
@immutable
class GameImage {
  final String iconPath;
  final String name;
  final int categoryId;

  const GameImage({
    required this.iconPath,
    required this.name,
    required this.categoryId,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'icon': iconPath,
        'name': name,
        'categoryId': categoryId,
      };

  /// Create from JSON
  factory GameImage.fromJson(Map<String, dynamic> json) {
    return GameImage(
      iconPath: json['icon'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as int,
    );
  }

  /// Check if this is an asset image
  bool get isAsset => iconPath.startsWith('assets/');

  /// Check if this is a file system image
  bool get isFile => !isAsset;

  /// Check if the image file exists (only for file system images)
  bool existsSync() {
    if (isAsset) return true; // Assume assets exist
    try {
      return File(iconPath).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Check if the image file exists asynchronously
  Future<bool> exists() async {
    if (isAsset) return true; // Assume assets exist
    try {
      return await File(iconPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Create a copy with modified fields
  GameImage copyWith({
    String? iconPath,
    String? name,
    int? categoryId,
  }) {
    return GameImage(
      iconPath: iconPath ?? this.iconPath,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameImage &&
          runtimeType == other.runtimeType &&
          iconPath == other.iconPath &&
          categoryId == other.categoryId;

  @override
  int get hashCode => iconPath.hashCode ^ categoryId.hashCode;

  @override
  String toString() =>
      'GameImage(name: $name, categoryId: $categoryId, path: $iconPath)';
}
