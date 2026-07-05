import 'package:flutter/material.dart';

import '../controllers/chess_board_controller.dart';
import 'chess_board/chess_board_controls.dart';
import 'chess_board/chess_board_debug_panel.dart';
import 'chess_board/chess_board_grid.dart';
import 'chess_board/chess_status_text.dart';

class ChessBoardWidget extends StatefulWidget {
  const ChessBoardWidget({super.key});

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  late final ChessBoardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChessBoardController()..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChessStatusText(text: _controller.statusText),
            const SizedBox(height: 12),
            ChessBoardControls(
              skillLevel: _controller.skillLevel,
              isBotThinking: _controller.isBotThinking,
              onNewGame: _controller.newGame,
              onRestart: _controller.restartGame,
              onSkillLevelChanged: _controller.setSkillLevel,
            ),
            const SizedBox(height: 16),
            ChessBoardGrid(
              playerIsWhite: _controller.playerIsWhite,
              highlights: _controller.highlights,
              pieceAt: _controller.pieceAt,
              canHumanMovePiece: _controller.canHumanMovePiece,
              canMoveTo: _controller.canMoveTo,
              legalTargetsFromSquare: _controller.legalTargetsFromSquare,
              onSquareTap: _controller.onSquareTap,
              onMove: _controller.tryHumanMove,
              onPieceDragStarted: _controller.selectSquare,
              onPieceDragEnded: _controller.clearSelectedSquare,
            ),
            const SizedBox(height: 16),
            ChessBoardDebugPanel(
              playerSide: _controller.playerSide,
              fen: _controller.fen,
              pgn: _controller.pgn,
              engineOutput: _controller.engineOutput,
            ),
          ],
        );
      },
    );
  }
}
