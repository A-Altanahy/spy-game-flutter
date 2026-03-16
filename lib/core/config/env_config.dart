/// Environment configuration for sensitive data
/// 
/// This class loads secrets from environment variables at compile time.
/// Never commit actual secrets to source control!
/// 
/// Usage:
/// 1. Set environment variables before running:
///    - DRIVE_API_KEY: Your Google Drive API key
///    - DRIVE_FOLDER_ID: Your Google Drive folder ID
/// 
/// 2. Run with dart-define:
///    flutter run --dart-define=DRIVE_API_KEY=your_key --dart-define=DRIVE_FOLDER_ID=your_folder
class EnvConfig {
  // Prevent instantiation
  EnvConfig._();

  // Placeholder for missing keys
  static const String _missingKey = 'MISSING_ENV_VAR';

  /// Google Drive API key
  /// Load from environment: DRIVE_API_KEY
  static const String driveApiKey = String.fromEnvironment(
    'DRIVE_API_KEY',
    defaultValue: _missingKey,
  );

  /// Google Drive folder ID
  /// Load from environment: DRIVE_FOLDER_ID
  static const String driveFolderId = String.fromEnvironment(
    'DRIVE_FOLDER_ID',
    defaultValue: _missingKey,
  );

  /// Check if all required environment variables are set
  static bool get isConfigured {
    return driveApiKey != _missingKey && driveFolderId != _missingKey;
  }

  /// Get list of missing environment variables
  static List<String> get missingVars {
    final missing = <String>[];
    if (driveApiKey == _missingKey) missing.add('DRIVE_API_KEY');
    if (driveFolderId == _missingKey) missing.add('DRIVE_FOLDER_ID');
    return missing;
  }

  /// Validate configuration and throw error if invalid
  static void validate() {
    if (!isConfigured) {
      throw Exception(
        'Missing required environment variables: ${missingVars.join(", ")}\n\n'
        'Please run with:\n'
        'flutter run --dart-define=DRIVE_API_KEY=your_key --dart-define=DRIVE_FOLDER_ID=your_folder',
      );
    }
  }
}
