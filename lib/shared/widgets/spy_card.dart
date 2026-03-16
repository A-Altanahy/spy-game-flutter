import 'package:flutter/material.dart';
import 'package:spyfall/core/theme/app_theme.dart';

class SpyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final bool showGlow;

  const SpyCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: (borderColor ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Main Card
          Card(
            color: color ?? AppTheme.surfaceBg,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: (borderColor ?? AppTheme.primaryColor)
                    .withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(24.0),
              child: child,
            ),
          ),

          // Tech Corners
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TechBorderPainter(
                  color: borderColor ?? AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechBorderPainter extends CustomPainter {
  final Color color;

  _TechBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double cornerSize = 15.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerSize),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerSize)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - cornerSize, size.height),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(cornerSize, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
