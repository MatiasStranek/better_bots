import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/piece_asset_utils.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    required this.piece,
    required this.square,
    required this.canDrag,
    required this.onDragStarted,
    required this.onDragEnded,
    super.key,
  });

  final chess.Piece piece;
  final String square;
  final bool canDrag;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    final assetPath = pieceAsset(piece);
    final keyValue = '$square-${piece.color}-${piece.type}-$assetPath';

    return LayoutBuilder(
      builder: (context, constraints) {
        final pieceSize = _resolvedPieceSize(constraints);
        final pieceVisual = _PieceVisual(assetPath: assetPath, keyValue: keyValue);
        final fullSquareChild = SizedBox.expand(child: pieceVisual);

        if (!canDrag) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: fullSquareChild,
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Draggable<String>(
            data: square,
            hitTestBehavior: HitTestBehavior.opaque,
            dragAnchorStrategy: (_, _, _) {
              return Offset(pieceSize / 2.0, pieceSize / 2.0);
            },
            feedback: SizedBox(
              width: pieceSize,
              height: pieceSize,
              child: Material(
                type: MaterialType.transparency,
                child: _PieceVisual(
                  assetPath: assetPath,
                  keyValue: 'feedback-$keyValue',
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.18, child: fullSquareChild),
            onDragStarted: onDragStarted,
            onDragEnd: (_) => onDragEnded(),
            child: fullSquareChild,
          ),
        );
      },
    );
  }

  double _resolvedPieceSize(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;
    final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 80.0;

    return math.min(maxWidth, maxHeight).clamp(48.0, 220.0).toDouble();
  }
}

class _PieceVisual extends StatelessWidget {
  const _PieceVisual({required this.assetPath, required this.keyValue});

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
