import 'package:flutter/foundation.dart';

/// Represents a category of images for the game
@immutable
class Category {
  final int id;
  final String name;
  final bool enabled;

  const Category({
    required this.id,
    required this.name,
    this.enabled = true,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
      };

  /// Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// Create a copy with modified fields
  Category copyWith({
    int? id,
    String? name,
    bool? enabled,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name, enabled: $enabled)';
}
