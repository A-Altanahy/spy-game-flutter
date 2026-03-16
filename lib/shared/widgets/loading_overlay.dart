import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';

/// A loading overlay widget that can be displayed over other content
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final double? progress;
  final String message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.progress,
    this.message = 'جاري التحميل...',
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              value: progress,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (progress != null && progress! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${(progress! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
