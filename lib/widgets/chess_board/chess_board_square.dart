import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../models/board_highlights.dart';
import 'chess_piece_widget.dart';

class ChessBoardSquare extends StatelessWidget {
  const ChessBoardSquare({
    required this.square,
    required this.piece,
    required this.isLightSquare,
    required this.highlights,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.legalTargetsFromSquare,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
    super.key,
  });

  final String square;
  final chess.Piece? piece;
  final bool isLightSquare;
  final BoardHighlights highlights;
  final bool canHumanMovePiece;
  final bool Function({required String from, required String to}) canMoveTo;
  final List<String> Function(String fromSquare) legalTargetsFromSquare;
  final Future<void> Function(String square) onSquareTap;
  final Future<bool> Function({required String from, required String to})
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
                if (isLegalTarget && piece == null)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isLegalTarget && piece != null)
                  Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withAlpha(90),
                        width: 4,
                      ),
                      shape: BoxShape.circle,
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
                if (piece != null)
                  ChessPieceWidget(
                    piece: piece!,
                    square: square,
                    canDrag: canHumanMovePiece,
                    onDragStarted: () => onPieceDragStarted(square),
                    onDragEnded: onPieceDragEnded,
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
      return Colors.white.withAlpha(18);
    }

    return Colors.black.withAlpha(22);
  }
}
