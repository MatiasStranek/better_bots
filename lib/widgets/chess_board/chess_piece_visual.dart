import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChessPieceVisual extends StatelessWidget {
  const ChessPieceVisual({
    super.key,
    required this.assetPath,
    required this.keyValue,
  });

  final String assetPath;
  final String keyValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 80.0,
        );
        final padding = (size * 0.015).clamp(1.0, 3.0).toDouble();
        final shadowOffset = Offset(size * 0.035, size * 0.045);

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: shadowOffset,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 1.15, sigmaY: 1.15),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(125),
                      BlendMode.srcIn,
                    ),
                    child: SvgPicture.asset(
                      assetPath,
                      key: ValueKey('shadow-$keyValue'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SvgPicture.asset(
                assetPath,
                key: ValueKey(keyValue),
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      },
    );
  }
}
