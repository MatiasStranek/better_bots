import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../../models/board_highlights.dart';
import 'mobile_chess_board_square.dart';

class MobileChessBoardView extends StatefulWidget {
  const MobileChessBoardView({
    super.key,
    required this.playerIsWhite,
    required this.pieceAt,
    required this.highlights,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
  });

  final bool playerIsWhite;
  final chess.Piece? Function(String square) pieceAt;

  final BoardHighlights highlights;

  final bool Function(String square) canHumanMovePiece;
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
  State<MobileChessBoardView> createState() => _MobileChessBoardViewState();
}

class _MobileChessBoardViewState extends State<MobileChessBoardView> {
  static const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const double _dragHoverCircleRadiusInSquares = 1.0;

  String? _hoveredDragTargetSquare;

  String _squareForIndex(int index) {
    final row = index ~/ 8;
    final column = index % 8;

    final fileIndex = widget.playerIsWhite ? column : 7 - column;
    final rank = widget.playerIsWhite ? 8 - row : row + 1;

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
    await widget.onSquareTap(square);
  }

  void _setHoveredDragTargetSquare(String? square) {
    if (_hoveredDragTargetSquare == square) {
      return;
    }

    setState(() {
      _hoveredDragTargetSquare = square;
    });
  }

  Offset _squareCenter(String square, double squareSize) {
    final file = square.substring(0, 1);
    final rank = int.parse(square.substring(1, 2));
    final fileIndex = _files.indexOf(file);

    final column = widget.playerIsWhite ? fileIndex : 7 - fileIndex;
    final row = widget.playerIsWhite ? 8 - rank : rank - 1;

    return Offset((column + 0.5) * squareSize, (row + 0.5) * squareSize);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final squareSize = boardSize / 8.0;

        return DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/board/maple.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) {
                  final square = _squareForIndex(index);
                  final piece = widget.pieceAt(square);
                  final pieceCode = _pieceCodeForPiece(piece);

                  return MobileChessBoardSquare(
                    square: square,
                    isLightSquare: _isLightSquare(square),
                    pieceCode: pieceCode,
                    highlights: widget.highlights,
                    canDrag: widget.canHumanMovePiece(square),
                    canMoveTo: widget.canMoveTo,
                    onSquareTap: _handleSquareTap,
                    onMove: widget.onMove,
                    onPieceDragStarted: widget.onPieceDragStarted,
                    onPieceDragEnded: widget.onPieceDragEnded,
                    onDragTargetHoverChanged: _setHoveredDragTargetSquare,
                  );
                },
              ),
              if (_hoveredDragTargetSquare != null)
                _MobileDragHoverCircle(
                  center: _squareCenter(_hoveredDragTargetSquare!, squareSize),
                  radius: squareSize * _dragHoverCircleRadiusInSquares,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDragHoverCircle extends StatelessWidget {
  const _MobileDragHoverCircle({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2.0;

    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(48),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
