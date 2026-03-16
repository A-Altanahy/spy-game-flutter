import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';

class SpyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double? width;
  final double? height;

  const SpyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        isPrimary ? AppTheme.primaryButtonStyle : AppTheme.secondaryButtonStyle;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style.copyWith(
          minimumSize:
              height != null ? WidgetStateProperty.all(Size(0, height!)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
