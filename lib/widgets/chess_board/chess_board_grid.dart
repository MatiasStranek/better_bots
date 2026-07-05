import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../models/board_highlights.dart';
import '../../utils/chess_square_utils.dart';
import 'chess_board_square.dart';

class ChessBoardGrid extends StatelessWidget {
  const ChessBoardGrid({
    required this.playerIsWhite,
    required this.highlights,
    required this.pieceAt,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.legalTargetsFromSquare,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
    super.key,
  });

  final bool playerIsWhite;
  final BoardHighlights highlights;
  final chess.Piece? Function(String square) pieceAt;
  final bool Function(String square) canHumanMovePiece;
  final bool Function({required String from, required String to}) canMoveTo;
  final List<String> Function(String fromSquare) legalTargetsFromSquare;
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/board/maple.jpg', fit: BoxFit.cover),
            ),
            GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                final square = squareNameFromIndex(
                  index: index,
                  playerIsWhite: playerIsWhite,
                );

                return ChessBoardSquare(
                  square: square,
                  piece: pieceAt(square),
                  isLightSquare: isLightSquareFromIndex(index),
                  highlights: highlights,
                  canHumanMovePiece: canHumanMovePiece(square),
                  canMoveTo: canMoveTo,
                  legalTargetsFromSquare: legalTargetsFromSquare,
                  onSquareTap: onSquareTap,
                  onMove: onMove,
                  onPieceDragStarted: onPieceDragStarted,
                  onPieceDragEnded: onPieceDragEnded,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
