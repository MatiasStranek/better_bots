import 'package:flutter/material.dart';

import '../models/maia_training_progress.dart';

class MaiaCompletionFill extends StatelessWidget {
  const MaiaCompletionFill({
    super.key,
    required this.completion,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.color = const Color(0xFF42B96A),
    this.opacity = 0.34,
  });

  final MaiaSideCompletion completion;
  final Widget child;
  final BorderRadius borderRadius;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!completion.any) {
      return child;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(
                painter: _MaiaCompletionPainter(
                  completion: completion,
                  color: color.withAlpha((opacity * 255).round()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaiaCompletionPainter extends CustomPainter {
  const _MaiaCompletionPainter({
    required this.completion,
    required this.color,
  });

  final MaiaSideCompletion completion;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    if (completion.both) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final center = size.width / 2;
    final diagonal = (size.height * 0.18).clamp(4.0, 12.0).toDouble();

    if (completion.white) {
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(center + diagonal, 0)
        ..lineTo(center - diagonal, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }

    if (completion.black) {
      final path = Path()
        ..moveTo(center + diagonal, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(center - diagonal, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MaiaCompletionPainter oldDelegate) {
    return oldDelegate.completion.white != completion.white ||
        oldDelegate.completion.black != completion.black ||
        oldDelegate.color != color;
  }
}
