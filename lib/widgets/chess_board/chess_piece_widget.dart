import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../utils/piece_asset_utils.dart';
import 'chess_piece_visual.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    required this.piece,
    required this.square,
    required this.canDrag,
    required this.onDragStarted,
    required this.onDragEnded,
    this.pieceCode,
    super.key,
  });

  final chess.Piece piece;
  final String square;

  /// Optional autoritativer Figurcode, z. B. direkt aus der FEN.
  /// Wenn dieser Wert gesetzt ist, wird er für den Asset-Pfad verwendet.
  final String? pieceCode;

  final bool canDrag;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    final resolvedPieceCode = pieceCode ?? chessPieceCode(piece);
    final assetPath = pieceAssetFromCode(resolvedPieceCode);
    final keyValue = '$square-$resolvedPieceCode-$assetPath-${piece.color}-${piece.type}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final pieceSize = _resolvedPieceSize(constraints);
        final pieceVisual = ChessPieceVisual(
          key: ValueKey(keyValue),
          assetPath: assetPath,
          keyValue: keyValue,
        );
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
                child: ChessPieceVisual(
                  key: ValueKey('feedback-$keyValue'),
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
    final maxHeight =
        constraints.maxHeight.isFinite ? constraints.maxHeight : 80.0;

    return math.min(maxWidth, maxHeight).clamp(48.0, 220.0).toDouble();
  }
}
