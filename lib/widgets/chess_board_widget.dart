import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/chess_board_controller.dart';
import '../models/player_side.dart';
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

    _controller = ChessBoardController(
      onPromotionChoiceRequested: _showPromotionChoiceDialog,
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _showPromotionChoiceDialog({
    required String from,
    required String to,
    required PlayerSide playerSide,
  }) async {
    if (!mounted) {
      return null;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final sideName = playerSide == PlayerSide.white ? 'Weiß' : 'Schwarz';

        return AlertDialog(
          title: const Text('Bauernumwandlung'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$sideName wandelt den Bauern von $from nach $to um.'),
              const SizedBox(height: 16),
              _PromotionButton(
                label: 'Dame',
                notation: 'q',
                icon: Icons.star,
                onSelected: (value) => Navigator.of(context).pop(value),
              ),
              const SizedBox(height: 8),
              _PromotionButton(
                label: 'Turm',
                notation: 'r',
                icon: Icons.castle,
                onSelected: (value) => Navigator.of(context).pop(value),
              ),
              const SizedBox(height: 8),
              _PromotionButton(
                label: 'Läufer',
                notation: 'b',
                icon: Icons.change_history,
                onSelected: (value) => Navigator.of(context).pop(value),
              ),
              const SizedBox(height: 8),
              _PromotionButton(
                label: 'Springer',
                notation: 'n',
                icon: Icons.pets,
                onSelected: (value) => Navigator.of(context).pop(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyPgnToClipboard() async {
    final pgn = _controller.pgn;

    if (pgn == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Noch keine PGN vorhanden.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: pgn));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PGN wurde kopiert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLoadFenDialog() async {
    final fenController = TextEditingController(text: _controller.fen);

    try {
      final fen = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: const Text('FEN laden'),
            content: SizedBox(
              width: 520,
              child: TextField(
                controller: fenController,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'FEN',
                  hintText:
                      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(fenController.text);
                },
                icon: const Icon(Icons.check),
                label: const Text('FEN bestätigen'),
              ),
            ],
          );
        },
      );

      if (fen == null) {
        return;
      }

      final loaded = await _controller.loadFenPosition(fen);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loaded ? 'FEN wurde geladen.' : 'FEN konnte nicht geladen werden.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      fenController.dispose();
    }
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyPgnToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('PGN kopieren'),
                ),
                OutlinedButton.icon(
                  onPressed: _showLoadFenDialog,
                  icon: const Icon(Icons.input),
                  label: const Text('FEN laden'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PromotionButton extends StatelessWidget {
  const _PromotionButton({
    required this.label,
    required this.notation,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final String notation;
  final IconData icon;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelected(notation),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
