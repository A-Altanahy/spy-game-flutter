import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';
import 'package:spyfall/core/constants/app_constants.dart';
import 'package:spyfall/data/models/game_settings.dart';
import 'package:spyfall/data/models/category.dart';
import 'package:spyfall/data/models/game_image.dart';
import 'package:spyfall/features/game/logic/game_logic.dart';
import 'package:spyfall/features/game/screens/role_reveal_screen.dart';
import 'package:spyfall/features/editor/screens/photo_editor_screen.dart';
import 'package:spyfall/main.dart' as main_app;
import 'package:spyfall/data/legacy/photos.dart' as photos;
import 'package:spyfall/shared/widgets/loading_overlay.dart';
import 'package:spyfall/shared/widgets/spy_card.dart';
import 'package:spyfall/shared/widgets/spy_button.dart';
import 'package:spyfall/core/localization/app_localizations.dart';
import 'package:spyfall/data/services/github_service.dart';

/// Home screen where players configure the game
class HomeScreen extends StatefulWidget {
  final int? initialPlayersCount;
  final int? initialSpiesCount;

  const HomeScreen({
    super.key,
    this.initialPlayersCount,
    this.initialSpiesCount,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late GameSettings _settings;
  bool _isLoading = false;
  double _downloadProgress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize game settings
    _settings = GameSettings(
      playerCount: widget.initialPlayersCount ?? AppConstants.defaultPlayers,
      spyCount: widget.initialSpiesCount ?? AppConstants.defaultSpies,
    );

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: AppConstants.fadeAnimationDuration),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Ensure photos data is initialized
    if (photos.categories.isEmpty) {
      photos.initPhotosData();
    }

    // Check download progress
    _checkDownloadProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check download progress periodically
  void _checkDownloadProgress() {
    if (main_app.isInitializing) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = main_app.isInitializing;
          });
          _checkDownloadProgress();
        }
      });
    } else if (_isLoading) {
      setState(() {
        _isLoading = false;
        _downloadProgress = 0;
      });
    }
  }

  /// Update player count
  void _updatePlayerCount(int delta) {
    final oldPlayerCount = _settings.playerCount;
    final newPlayerCount = (_settings.playerCount + delta)
        .clamp(AppConstants.minPlayers, AppConstants.maxPlayers);

    if (newPlayerCount != oldPlayerCount) {
      setState(() {
        _settings = _settings.copyWith(playerCount: newPlayerCount);

        // Auto-adjust spy count based on rule: 1 spy per 3 players
        // 3-5 players = 1 spy
        // 6-8 players = 2 spies
        // 9-11 players = 3 spies
        int recommendedSpyCount = (newPlayerCount / 3).floor();

        // Ensure at least 1 spy
        if (recommendedSpyCount < 1) recommendedSpyCount = 1;

        // Ensure spy count doesn't exceed players - 1 (though logic above handles this mostly)
        if (recommendedSpyCount >= newPlayerCount) {
          recommendedSpyCount = newPlayerCount - 1;
        }

        _settings = _settings.copyWith(spyCount: recommendedSpyCount);
      });
    }
  }

  /// Update spy count
  void _updateSpyCount(int delta) {
    final newSpyCount = (_settings.spyCount + delta)
        .clamp(AppConstants.minSpies, _settings.playerCount - 1);

    setState(() {
      _settings = _settings.copyWith(spyCount: newSpyCount);
    });
  }

  /// Start the game
  Future<void> _startGame() async {
    // Convert photos data to models
    final categories =
        photos.categories.map((cat) => Category.fromJson(cat)).toList();
    final images = photos.images.map((img) => GameImage.fromJson(img)).toList();

    // Validate game start
    final validation = await GameLogic.validateGameStart(
      _settings,
      categories,
      images,
    );

    if (!validation.isValid) {
      if (validation.showCategoryDialog) {
        _showValidationDialog(validation);
      } else {
        _showErrorSnackBar(validation.errorMessage ?? 'خطأ غير معروف');
      }
      return;
    }

    // Select random location
    final location = await GameLogic.selectRandomLocation(categories, images);
    if (location == null) {
      _showErrorSnackBar('فشل في اختيار الموقع');
      return;
    }

    // Navigate to game screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RoleRevealScreen(
            settings: _settings,
            chosenLocation: location,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(
            milliseconds: AppConstants.pageTransitionDuration,
          ),
        ),
      );
    }
  }

  /// Show validation dialog
  void _showValidationDialog(GameValidationResult validation) {
    final hasEmptyCategories = validation.categoriesWithoutImages.isNotEmpty;
    final hasInaccessibleImages =
        validation.categoriesWithInaccessibleImages.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.5)),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.translate('systemAlert'),
                  style: const TextStyle(color: AppTheme.warning)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  validation.errorMessage ??
                      AppLocalizations.of(context)!
                          .translate('cannotStartGame'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (hasEmptyCategories) ...[
                  const SizedBox(height: 12),
                  Text(
                      AppLocalizations.of(context)!
                          .translate('emptyCategories'),
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...validation.categoriesWithoutImages.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Text(
                        '• ${cat.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                if (hasInaccessibleImages) ...[
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!
                      .translate('inaccessibleImages')),
                ],
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('addImagesHint'),
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            SpyButton(
              text: AppLocalizations.of(context)!.translate('editCategories'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PhotosEditor()),
                );
                setState(() {});
              },
              isPrimary: true,
            ),
          ],
        );
      },
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PhotosEditor()),
        ).then((_) {
          setState(() {});
        }),
        backgroundColor: AppTheme.primaryColor,
        tooltip: AppLocalizations.of(context)!.translate('editCategories'),
        child: const Icon(Icons.settings),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),

          // Tech Pattern Overlay
          Opacity(
            opacity: 0.05,
            child: CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60), // Space for Custom AppBar
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.contentPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Player count card
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.0, 0.6,
                                  curve: Curves.easeOutBack),
                            )),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SpyCard(
                                showGlow: true,
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('playerCount'),
                                      style: AppTheme.subheadingStyle.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildCounterButton(
                                          icon: Icons.remove,
                                          onPressed: () =>
                                              _updatePlayerCount(-1),
                                        ),
                                        Container(
                                          width: 80,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${_settings.playerCount}',
                                            style: AppTheme.headingStyle
                                                .copyWith(fontSize: 48),
                                          ),
                                        ),
                                        _buildCounterButton(
                                          icon: Icons.add,
                                          onPressed: () =>
                                              _updatePlayerCount(1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Spy count card
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.2, 0.8,
                                  curve: Curves.easeOutBack),
                            )),
                            child: FadeTransition(
                              opacity:
                                  Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: const Interval(0.2, 1.0,
                                      curve: Curves.easeIn),
                                ),
                              ),
                              child: SpyCard(
                                borderColor: AppTheme.accentColor,
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('spyCount'),
                                      style: AppTheme.subheadingStyle.copyWith(
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildCounterButton(
                                          icon: Icons.remove,
                                          onPressed: () => _updateSpyCount(-1),
                                          color: AppTheme.accentColor,
                                        ),
                                        Container(
                                          width: 80,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${_settings.spyCount}',
                                            style:
                                                AppTheme.headingStyle.copyWith(
                                              fontSize: 48,
                                              color: AppTheme.accentColor,
                                            ),
                                          ),
                                        ),
                                        _buildCounterButton(
                                          icon: Icons.add,
                                          onPressed: () => _updateSpyCount(1),
                                          color: AppTheme.accentColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Start game button
                          ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.4, 1.0,
                                  curve: Curves.elasticOut),
                            ),
                            child: SpyButton(
                              text: AppLocalizations.of(context)!
                                  .translate('startMission'),
                              onPressed: _startGame,
                              width: double.infinity,
                              height: 65,
                              icon: Icons.play_arrow_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Title
                    Text(
                      'SPYFALL',
                      style: AppTheme.currentTheme.appBarTheme.titleTextStyle,
                    ),

                    // Language Switcher (Always Left)
                    Positioned(
                      left: 0,
                      child: ValueListenableBuilder<Locale>(
                        valueListenable: main_app.appLocaleNotifier,
                        builder: (context, locale, child) {
                          return Material(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () async {
                                final newLocale = locale.languageCode == 'ar'
                                    ? const Locale('en')
                                    : const Locale('ar');
                                main_app.appLocaleNotifier.value = newLocale;

                                // Trigger content sync to update localized names
                                try {
                                  // Try local caching first for instant switch
                                  bool success =
                                      await photos.applyContentLanguage(
                                          newLocale.languageCode);

                                  if (!success) {
                                    // Only show loading if we need to fetch from network
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = true;
                                        _downloadProgress = 0;
                                      });
                                    }

                                    // Fallback to fetching ONLY translations if local files missing
                                    // This is much faster than full sync and doesn't check images
                                    await GithubService().fetchTranslations();

                                    // Try applying again
                                    await photos.applyContentLanguage(
                                        newLocale.languageCode);
                                  }

                                  // Force rebuild to show new names
                                  if (mounted) setState(() {});
                                } catch (e) {
                                  // print('Error switching content language: $e');
                                } finally {
                                  if (mounted && _isLoading) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      color: AppTheme.primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      locale.languageCode == 'ar'
                                          ? 'English'
                                          : 'عربي',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          LoadingOverlay(
            isLoading: _isLoading,
            progress: _downloadProgress > 0 ? _downloadProgress : null,
            message: AppLocalizations.of(context)!.translate('loadingData'),
          ),
        ],
      ),
    );
  }

  /// Build a counter button
  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final btnColor = color ?? AppTheme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: btnColor.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
        color: btnColor.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: btnColor,
        iconSize: 32,
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double gridSize = 40.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
