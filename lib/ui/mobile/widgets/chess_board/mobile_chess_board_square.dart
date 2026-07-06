import 'package:flutter/material.dart';

import 'mobile_chess_piece.dart';

class MobileChessBoardSquare extends StatelessWidget {
  const MobileChessBoardSquare({
    super.key,
    required this.square,
    required this.isLightSquare,
    required this.pieceCode,
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
    final squareColor = isLightSquare
        ? const Color(0x99F0D9B5)
        : const Color(0x99946F51);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final from = details.data;
        return canMoveTo(from: from, to: square);
      },
      onAcceptWithDetails: (details) async {
        final from = details.data;
        await onMove(from: from, to: square);
      },
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await onSquareTap(square);
          },
          child: ColoredBox(
            color: isDragTarget
                ? Colors.greenAccent.withAlpha(120)
                : squareColor,
            child: pieceCode == null
                ? const SizedBox.expand()
                : _DraggableMobilePiece(
                    square: square,
                    pieceCode: pieceCode!,
                    canDrag: canDrag,
                    onPieceDragStarted: onPieceDragStarted,
                    onPieceDragEnded: onPieceDragEnded,
                  ),
          ),
        );
      },
    );
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
        child: SizedBox(width: 56, height: 56, child: piece),
      ),
      childWhenDragging: const SizedBox.expand(),
      onDragStarted: () => onPieceDragStarted(square),
      onDragEnd: (_) => onPieceDragEnded(),
      onDraggableCanceled: (_, __) => onPieceDragEnded(),
      child: piece,
    );
  }
}
