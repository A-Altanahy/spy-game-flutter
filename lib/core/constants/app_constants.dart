/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // Game Configuration
  static const int minPlayers = 3;
  static const int maxPlayers = 100;
  static const int minSpies = 1;
  static const int defaultPlayers = 3;
  static const int defaultSpies = 1;

  // Network Timeouts (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;
  static const int shortTimeout = 10;
  static const int longTimeout = 60;

  // UI Configuration
  static const int gridCrossAxisCount = 4;
  static const double gridSpacing = 10.0;
  static const double cardElevation = 8.0;
  static const double buttonElevation = 4.0;
  static const double borderRadius = 16.0;

  // Animation Durations (in milliseconds)
  static const int fadeAnimationDuration = 800;
  static const int scaleAnimationDuration = 400;
  static const int pageTransitionDuration = 300;

  // Storage Keys
  static const String categoriesKey = 'categories';
  static const String imagesKey = 'images';
  static const String lastUpdateTimeKey = 'last_update_time';

  // File Paths
  static const String spyImageAssetPath = 'assets/images/spy.png';
  static const String spyImageFolderPath = 'spyfall_images';
  static const String spyImageFileName = 'spy.png';

  // Special IDs
  static const int spyCategoryId = 0;

  // Validation Messages (Arabic)
  static const String minPlayersError = 'يجب أن يكون عدد اللاعبين 3 على الأقل';
  static const String minSpiesError = 'يجب أن يكون هناك جاسوس واحد على الأقل';
  static const String spiesExceedPlayersError =
      'عدد الجواسيس يجب أن يكون أقل من عدد اللاعبين';
  static const String noCategoriesEnabledError =
      'يجب عليك تفعيل فئة واحدة على الأقل للعب';
  static const String noImagesAvailableError =
      'لا توجد صور متاحة في الفئات المفعلة';
}
