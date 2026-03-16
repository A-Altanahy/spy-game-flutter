import 'package:flutter/foundation.dart';
import 'package:spyfall/core/constants/app_constants.dart';

/// Represents the game configuration settings
@immutable
class GameSettings {
  final int playerCount;
  final int spyCount;

  const GameSettings({
    required this.playerCount,
    required this.spyCount,
  });

  /// Default game settings
  factory GameSettings.defaultSettings() => const GameSettings(
        playerCount: AppConstants.defaultPlayers,
        spyCount: AppConstants.defaultSpies,
      );

  /// Check if the settings are valid
  bool get isValid =>
      playerCount >= AppConstants.minPlayers &&
      spyCount > 0 &&
      spyCount < playerCount;

  /// Get validation error message if settings are invalid
  String? get validationError {
    if (playerCount < AppConstants.minPlayers) {
      return AppConstants.minPlayersError;
    }
    if (spyCount <= 0) {
      return AppConstants.minSpiesError;
    }
    if (spyCount >= playerCount) {
      return AppConstants.spiesExceedPlayersError;
    }
    return null;
  }

  /// Calculate recommended spy count based on player count
  static int calculateRecommendedSpyCount(int playerCount) {
    if (playerCount < AppConstants.minPlayers) return 1;
    // Formula: 3-5 players: 1 spy, 6-8 players: 2 spies, etc.
    int recommendedSpyCount = ((playerCount - 3) / 3).floor() + 1;
    // Ensure we don't exceed valid limits
    return recommendedSpyCount.clamp(1, playerCount - 1);
  }

  /// Create a copy with modified fields
  GameSettings copyWith({
    int? playerCount,
    int? spyCount,
  }) {
    return GameSettings(
      playerCount: playerCount ?? this.playerCount,
      spyCount: spyCount ?? this.spyCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettings &&
          runtimeType == other.runtimeType &&
          playerCount == other.playerCount &&
          spyCount == other.spyCount;

  @override
  int get hashCode => playerCount.hashCode ^ spyCount.hashCode;

  @override
  String toString() =>
      'GameSettings(playerCount: $playerCount, spyCount: $spyCount)';
}
