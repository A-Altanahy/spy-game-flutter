import 'package:spyfall/core/constants/app_constants.dart';
import 'package:spyfall/data/models/game_settings.dart';

/// Validation logic for home screen
class HomeValidator {
  /// Validate player count
  static String? validatePlayerCount(int playerCount) {
    if (playerCount < AppConstants.minPlayers) {
      return AppConstants.minPlayersError;
    }
    return null;
  }

  /// Validate spy count
  static String? validateSpyCount(int spyCount, int playerCount) {
    if (spyCount <= 0) {
      return AppConstants.minSpiesError;
    }
    if (spyCount >= playerCount) {
      return AppConstants.spiesExceedPlayersError;
    }
    return null;
  }

  /// Validate game settings
  static String? validateGameSettings(GameSettings settings) {
    return settings.validationError;
  }

  /// Check if counts are valid
  static bool areCountsValid(int playerCount, int spyCount) {
    return playerCount >= AppConstants.minPlayers &&
        spyCount > 0 &&
        spyCount < playerCount;
  }
}

