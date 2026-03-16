import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';
import 'package:spyfall/data/models/game_image.dart';
import 'package:spyfall/features/home/screens/home_screen.dart';
import 'package:spyfall/shared/widgets/spy_card.dart';
import 'package:spyfall/shared/widgets/bottom_action_button.dart';

import 'package:spyfall/core/localization/app_localizations.dart';

/// Screen shown at the end of the game
class EndGameScreen extends StatefulWidget {
  final int spyCount;
  final int playerCount;
  final GameImage? chosenLocation;

  const EndGameScreen({
    super.key,
    required this.spyCount,
    required this.playerCount,
    this.chosenLocation,
  });

  @override
  State<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends State<EndGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SpyCard(
                        showGlow: true,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('letsFindSpy'),
                                style: AppTheme.headingStyle.copyWith(
                                  fontSize: 28,
                                  color: AppTheme.primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.accentColor
                                      .withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: AppTheme.accentColor
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  size: 80,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('investigationStarts'),
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('gameRules'),
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        height: 1.6,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Play again button at bottom
                BottomActionButton(
                  text: AppLocalizations.of(context)!
                      .translate('startNewMission'),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          HomeScreen(
                        initialPlayersCount: widget.playerCount,
                        initialSpiesCount: widget.spyCount,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  icon: Icons.replay_circle_filled,
                ),
                const SizedBox(
                    height: 20), // Add spacing to match RoleRevealScreen
              ],
            ),
          ),
        ),
      ),
    );
  }
}
