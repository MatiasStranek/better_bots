import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import 'mobile_chess_board_square.dart';

class MobileChessBoardView extends StatelessWidget {
  const MobileChessBoardView({
    super.key,
    required this.playerIsWhite,
    required this.pieceAt,
    required this.onSquareTap,
  });

  final bool playerIsWhite;
  final chess.Piece? Function(String square) pieceAt;
  final Future<void> Function(String square) onSquareTap;

  static const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  String _squareForIndex(int index) {
    final row = index ~/ 8;
    final column = index % 8;

    final fileIndex = playerIsWhite ? column : 7 - column;
    final rank = playerIsWhite ? 8 - row : row + 1;

    return '${_files[fileIndex]}$rank';
  }

  bool _isLightSquare(String square) {
    final file = square.substring(0, 1);
    final rank = int.parse(square.substring(1, 2));
    final fileIndex = _files.indexOf(file);

    return (fileIndex + rank).isEven;
  }

  String? _pieceCodeForPiece(chess.Piece? piece) {
    if (piece == null) {
      return null;
    }

    final colorPrefix = piece.color == chess.Color.WHITE ? 'w' : 'b';
    final pieceType = _pieceLetter(piece);

    return '$colorPrefix$pieceType';
  }

  String _pieceLetter(chess.Piece piece) {
    final typeText = piece.type.toString().toLowerCase();

    if (typeText == 'p' ||
        typeText.endsWith('.p') ||
        typeText.contains('pawn')) {
      return 'P';
    }

    if (typeText == 'n' ||
        typeText.endsWith('.n') ||
        typeText.contains('knight')) {
      return 'N';
    }

    if (typeText == 'b' ||
        typeText.endsWith('.b') ||
        typeText.contains('bishop')) {
      return 'B';
    }

    if (typeText == 'r' ||
        typeText.endsWith('.r') ||
        typeText.contains('rook')) {
      return 'R';
    }

    if (typeText == 'q' ||
        typeText.endsWith('.q') ||
        typeText.contains('queen')) {
      return 'Q';
    }

    if (typeText == 'k' ||
        typeText.endsWith('.k') ||
        typeText.contains('king')) {
      return 'K';
    }

    return 'P';
  }

  Future<void> _handleSquareTap(String square) async {
    await onSquareTap(square);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/board/maple.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            final square = _squareForIndex(index);
            final piece = pieceAt(square);
            final pieceCode = _pieceCodeForPiece(piece);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleSquareTap(square),
              child: MobileChessBoardSquare(
                isLightSquare: _isLightSquare(square),
                pieceCode: pieceCode,
              ),
            );
          },
        ),
      ),
    );
  }
}
