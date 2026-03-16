import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';
import 'package:spyfall/core/constants/app_constants.dart';
import 'package:spyfall/data/models/game_image.dart';
import 'package:spyfall/data/models/game_settings.dart';
import 'package:spyfall/features/game/screens/end_game_screen.dart';
import 'package:spyfall/shared/widgets/spy_card.dart';
import 'package:spyfall/shared/widgets/bottom_action_button.dart';
import 'package:spyfall/core/localization/app_localizations.dart';

/// Screen where players reveal their roles one by one
class RoleRevealScreen extends StatefulWidget {
  final GameSettings settings;
  final GameImage chosenLocation;

  const RoleRevealScreen({
    super.key,
    required this.settings,
    required this.chosenLocation,
  });

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _playerRoles;
  late String _currentRole;
  late bool _isSpy;
  bool _isReady = false;
  int _currentPlayerNumber = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: AppConstants.scaleAnimationDuration),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Generate player roles
    _playerRoles = _generatePlayerRoles();

    // Assign first role
    _currentRole = _playerRoles.removeAt(0);
    _isSpy = _currentRole == "جاسوس";

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Generate list of player roles (spies and regular players)
  List<String> _generatePlayerRoles() {
    final roles = List.generate(
          widget.settings.playerCount - widget.settings.spyCount,
          (_) => "صالح",
        ) +
        List.generate(widget.settings.spyCount, (_) => "جاسوس");

    roles.shuffle();
    return roles;
  }

  /// Move to next player's role
  void _nextPlayer() {
    if (_playerRoles.isEmpty) {
      // Reset in case we run out
      _playerRoles = _generatePlayerRoles();
    }

    setState(() {
      _currentRole = _playerRoles.removeAt(0);
      _isSpy = _currentRole == "جاسوس";
    });

    _animationController.reset();
    _animationController.forward();
  }

  /// Handle "Ready" button press
  void _handleReady() {
    _animationController.reset();
    setState(() {
      _isReady = true;
    });
    _animationController.forward();
  }

  /// Navigate to next player or end game
  void _handleNext() {
    if (_currentPlayerNumber < widget.settings.playerCount) {
      setState(() {
        _currentPlayerNumber++;
        _isReady = false;
      });
      _nextPlayer();
    } else {
      // All players have seen their roles, go to end game
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              EndGameScreen(
            spyCount: widget.settings.spyCount,
            playerCount: widget.settings.playerCount,
            chosenLocation: widget.chosenLocation,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Player card
                  if (!_isReady) _buildPlayerNumberCard() else _buildRoleCard(),

                  // Next button (only shown after player sees their role)
                  if (_isReady) ...[
                    const Spacer(),
                    BottomActionButton(
                      text: _currentPlayerNumber < widget.settings.playerCount
                          ? AppLocalizations.of(context)!.translate('next')
                          : AppLocalizations.of(context)!.translate('finish'),
                      onPressed: _handleNext,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the card showing player number
  Widget _buildPlayerNumberCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SpyCard(
        showGlow: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.of(context)!.translate('player')} $_currentPlayerNumber',
                style: AppTheme.headingStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: _handleReady,
                  child: Text(
                    AppLocalizations.of(context)!.translate('ready'),
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the card showing the role
  Widget _buildRoleCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SpyCard(
        borderColor: _isSpy ? AppTheme.accentColor : AppTheme.primaryColor,
        showGlow: true,
        child: Container(
          height: 450, // Fixed height for role card to prevent jumping
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSpy)
                Expanded(child: _buildSpyContent())
              else
                Expanded(child: _buildRegularPlayerContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// Build content for spy role
  Widget _buildSpyContent() {
    return Column(
      children: [
        Text(
          '${AppLocalizations.of(context)!.translate('player')} $_currentPlayerNumber',
          style: AppTheme.headingStyle.copyWith(
            color: AppTheme.primaryColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context)!.translate('youAreSpy'),
          style: AppTheme.headingStyle.copyWith(
            color: AppTheme.accentColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  AppConstants.spyImageAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_search,
                      size: 100,
                      color: AppTheme.accentColor,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('spyObjective'),
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Build content for regular player role
  Widget _buildRegularPlayerContent() {
    return Column(
      children: [
        Text(
          '${AppLocalizations.of(context)!.translate('player')} $_currentPlayerNumber',
          style: AppTheme.headingStyle.copyWith(
            color: AppTheme.primaryColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.chosenLocation.name,
          style: AppTheme.headingStyle.copyWith(
            color: AppTheme.secondaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildLocationImage(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the location image widget
  Widget _buildLocationImage() {
    if (widget.chosenLocation.isAsset) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          widget.chosenLocation.iconPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.place,
              size: 70,
              color: AppTheme.primaryColor,
            );
          },
        ),
      );
    } else {
      // File image
      final file = File(widget.chosenLocation.iconPath);
      if (file.existsSync()) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.place,
                size: 70,
                color: AppTheme.primaryColor,
              );
            },
          ),
        );
      } else {
        // Fallback to spy image
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            AppConstants.spyImageAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.place,
                size: 70,
                color: AppTheme.primaryColor,
              );
            },
          ),
        );
      }
    }
  }
}
