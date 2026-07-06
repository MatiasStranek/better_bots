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

  @override
  Widget build(BuildContext context) {
    final isSelected = highlights.isSelected(square);
    final isLegalTarget = highlights.isLegalTarget(square);
    final isLastMove = highlights.isLastMove(square);
    final isPremove = highlights.isPremove(square);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return canMoveTo(from: details.data, to: square);
      },
      onAcceptWithDetails: (details) async {
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
                    onPieceDragEnded: onPieceDragEnded,
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
    if (isDragTarget) {
      return Colors.greenAccent.withAlpha(100);
    }

    if (isSelected) {
      return Colors.blueAccent.withAlpha(90);
    }

    if (isPremove) {
      return Colors.deepPurpleAccent.withAlpha(90);
    }

    if (isLegalTarget) {
      return Colors.green.withAlpha(70);
    }

    if (isLastMove) {
      return Colors.yellow.withAlpha(80);
    }

    if (isLightSquare) {
      return const Color(0x99F0D9B5);
    }

    return const Color(0x99946F51);
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

  @override
  Widget build(BuildContext context) {
    final piece = MobileChessPiece(pieceCode: pieceCode);

    if (!canDrag) {
      return piece;
    }

    return Draggable<String>(
      data: square,

      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Transform.scale(scale: 1.18, child: piece),
        ),
      ),

      childWhenDragging: Opacity(opacity: .25, child: piece),

      onDragStarted: () => onPieceDragStarted(square),
      onDragEnd: (_) => onPieceDragEnded(),
      onDraggableCanceled: (_, __) => onPieceDragEnded(),

      child: piece,
    );
  }
}
