import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../models/board_highlights.dart';
import 'mobile_chess_piece.dart';

class MobileChessBoardSquare extends StatelessWidget {
  const MobileChessBoardSquare({
    super.key,
    required this.square,
    required this.isLightSquare,
    required this.pieceCode,
    required this.highlights,
    required this.canDrag,
    required this.canMoveTo,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
    required this.onDragTargetHoverChanged,
  });

  final String square;
  final bool isLightSquare;
  final String? pieceCode;

  final BoardHighlights highlights;

  final bool canDrag;

  final bool Function({required String from, required String to}) canMoveTo;

  final Future<void> Function(String square) onSquareTap;

  final Future<bool> Function({
    required String from,
    required String to,
    String? promotion,
  })
  onMove;

  final ValueChanged<String> onPieceDragStarted;
  final VoidCallback onPieceDragEnded;
  final ValueChanged<String?> onDragTargetHoverChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = highlights.isSelected(square);
    final isLegalTarget = highlights.isLegalTarget(square);
    final isLastMove = highlights.isLastMove(square);
    final isPremove = highlights.isPremove(square);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        onDragTargetHoverChanged(square);

        return canMoveTo(from: details.data, to: square);
      },
      onMove: (_) {
        onDragTargetHoverChanged(square);
      },
      onLeave: (_) {
        onDragTargetHoverChanged(null);
      },
      onAcceptWithDetails: (details) async {
        onDragTargetHoverChanged(null);
        await onMove(from: details.data, to: square);
      },
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await onSquareTap(square);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _squareColor(
                isLightSquare: isLightSquare,
                isSelected: isSelected,
                isLegalTarget: isLegalTarget,
                isLastMove: isLastMove,
                isDragTarget: isDragTarget,
                isPremove: isPremove,
              ),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLegalTarget && pieceCode == null)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                  ),

                if (isLegalTarget && pieceCode != null)
                  Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withAlpha(90),
                        width: 4,
                      ),
                    ),
                  ),

                if (isPremove)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withAlpha(220),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                if (pieceCode != null)
                  _DraggableMobilePiece(
                    square: square,
                    pieceCode: pieceCode!,
                    canDrag: canDrag,
                    onPieceDragStarted: onPieceDragStarted,
                    onPieceDragEnded: () {
                      onDragTargetHoverChanged(null);
                      onPieceDragEnded();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _squareColor({
    required bool isLightSquare,
    required bool isSelected,
    required bool isLegalTarget,
    required bool isLastMove,
    required bool isDragTarget,
    required bool isPremove,
  }) {
    if (isSelected) {
      return Colors.blueAccent.withAlpha(90);
    }

    if (isPremove) {
      return Colors.deepPurpleAccent.withAlpha(90);
    }

    if (isLastMove) {
      return Colors.yellow.withAlpha(80);
    }

    return Colors.transparent;
  }
}

class _DraggableMobilePiece extends StatelessWidget {
  const _DraggableMobilePiece({
    required this.square,
    required this.pieceCode,
    required this.canDrag,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
  });

  final String square;
  final String pieceCode;
  final bool canDrag;

  final ValueChanged<String> onPieceDragStarted;
  final VoidCallback onPieceDragEnded;

  static const double _dragFeedbackScale = 2.0;
  static const double _dragFingerAnchorY = 0.94;

  @override
  Widget build(BuildContext context) {
    final piece = MobileChessPiece(pieceCode: pieceCode);

    if (!canDrag) {
      return piece;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSize = _resolvedSquareSize(constraints);
        final feedbackSize = squareSize * _dragFeedbackScale;

        return Draggable<String>(
          data: square,
          hitTestBehavior: HitTestBehavior.opaque,
          dragAnchorStrategy: (_, _, _) {
            return Offset(feedbackSize / 2.0, feedbackSize * _dragFingerAnchorY);
          },
          feedback: SizedBox.square(
            dimension: feedbackSize,
            child: Material(type: MaterialType.transparency, child: piece),
          ),
          childWhenDragging: Opacity(opacity: 0.18, child: piece),
          onDragStarted: () => onPieceDragStarted(square),
          onDragEnd: (_) => onPieceDragEnded(),
          onDraggableCanceled: (_, __) => onPieceDragEnded(),
          child: piece,
        );
      },
    );
  }

  double _resolvedSquareSize(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;
    final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 80.0;

    return math.min(maxWidth, maxHeight).clamp(48.0, 220.0).toDouble();
  }
}
