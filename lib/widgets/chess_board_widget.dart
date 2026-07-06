import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/chess_board_controller.dart';
import '../models/board_annotation.dart';
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
  late final FocusNode _keyboardFocusNode;

  final Set<String> _normalAnnotationMarkedSquares = <String>{};
  final Set<BoardArrowAnnotation> _normalAnnotationArrows =
      <BoardArrowAnnotation>{};
  final Set<String> _analysisAnnotationMarkedSquares = <String>{};
  final Set<BoardArrowAnnotation> _analysisAnnotationArrows =
      <BoardArrowAnnotation>{};

  bool _lastKnownAnalysisMode = false;

  @override
  void initState() {
    super.initState();

    _keyboardFocusNode = FocusNode(debugLabel: 'ChessBoardAnalysisShortcuts');
    _controller = ChessBoardController(
      onPromotionChoiceRequested: _showPromotionChoiceDialog,
    )..start();
    _lastKnownAnalysisMode = _controller.isAnalysisMode;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Set<String> get _activeAnnotationMarkedSquares {
    return _controller.isAnalysisMode
        ? _analysisAnnotationMarkedSquares
        : _normalAnnotationMarkedSquares;
  }

  Set<BoardArrowAnnotation> get _activeAnnotationArrows {
    return _controller.isAnalysisMode
        ? _analysisAnnotationArrows
        : _normalAnnotationArrows;
  }

  void _handleControllerChanged() {
    final isAnalysisMode = _controller.isAnalysisMode;
    final hasJustLeftAnalysisMode = _lastKnownAnalysisMode && !isAnalysisMode;

    _lastKnownAnalysisMode = isAnalysisMode;

    if (!hasJustLeftAnalysisMode ||
        (_analysisAnnotationMarkedSquares.isEmpty &&
            _analysisAnnotationArrows.isEmpty)) {
      return;
    }

    if (!mounted) {
      _analysisAnnotationMarkedSquares.clear();
      _analysisAnnotationArrows.clear();
      return;
    }

    setState(() {
      _analysisAnnotationMarkedSquares.clear();
      _analysisAnnotationArrows.clear();
    });
  }

  void _clearBoardAnnotations() {
    final markedSquares = _activeAnnotationMarkedSquares;
    final arrows = _activeAnnotationArrows;

    if (markedSquares.isEmpty && arrows.isEmpty) {
      return;
    }

    setState(() {
      markedSquares.clear();
      arrows.clear();
    });
  }

  void _toggleAnnotationSquare(String square) {
    final markedSquares = _activeAnnotationMarkedSquares;

    setState(() {
      if (!markedSquares.add(square)) {
        markedSquares.remove(square);
      }
    });
  }

  void _toggleAnnotationArrow(BoardArrowAnnotation arrow) {
    final arrows = _activeAnnotationArrows;

    setState(() {
      if (!arrows.add(arrow)) {
        arrows.remove(arrow);
      }
    });
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
    if (_controller.isAnalysisMode) {
      return;
    }

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

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (!_controller.isAnalysisMode) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _controller.stepAnalysisBack();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _controller.stepAnalysisForward();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChessStatusText(text: _controller.statusText),
              const SizedBox(height: 12),
              ChessBoardControls(
                skillLevel: _controller.skillLevel,
                uciElo: _controller.uciElo,
                cpLossElo: _controller.cpLossElo,
                cpLossUciSwitchFullMoveNumber:
                    _controller.cpLossUciSwitchFullMoveNumber,
                strengthMode: _controller.strengthMode,
                botOpeningMove: _controller.botOpeningMove,
                botPersonality: _controller.botPersonality,
                effectiveBotPersonality: _controller.effectiveBotPersonality,
                personaCandidateCount: _controller.personaCandidateCount,
                isBotThinking: _controller.isBotThinking,
                isAnalysisMode: _controller.isAnalysisMode,
                canNavigateAnalysisBack: _controller.canNavigateAnalysisBack,
                canNavigateAnalysisForward:
                    _controller.canNavigateAnalysisForward,
                onNewGame: _controller.newGame,
                onRestart: _controller.restartGame,
                onToggleAnalysisMode: _controller.toggleAnalysisMode,
                onAnalysisBack: _controller.stepAnalysisBack,
                onAnalysisForward: _controller.stepAnalysisForward,
                onSkillLevelChanged: _controller.setSkillLevel,
                onUciEloChanged: _controller.setUciElo,
                onCpLossEloChanged: _controller.setCpLossElo,
                onCpLossUciSwitchFullMoveNumberChanged:
                    _controller.setCpLossUciSwitchFullMoveNumber,
                onStrengthModeChanged: _controller.setStrengthMode,
                onBotOpeningMoveChanged: _controller.setBotOpeningMove,
                onBotPersonalityChanged: _controller.setBotPersonality,
                onPersonaCandidateCountChanged:
                    _controller.setPersonaCandidateCount,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    annotationModeEnabled: true,
                    annotationMarkedSquares: _activeAnnotationMarkedSquares,
                    annotationArrows: _activeAnnotationArrows,
                    onClearAnnotations: _clearBoardAnnotations,
                    onToggleAnnotationSquare: _toggleAnnotationSquare,
                    onToggleAnnotationArrow: _toggleAnnotationArrow,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChessBoardDebugPanel(
                            playerSide: _controller.playerSide,
                            fen: _controller.fen,
                            pgn: _controller.pgn,
                            engineOutput: _controller.engineOutput,
                            isAnalysisMode: _controller.isAnalysisMode,
                            isAnalysisThinking: _controller.isAnalysisThinking,
                            analysisLines: _controller.analysisLines,
                          ),
                          const SizedBox(height: 12),
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
                                onPressed: _controller.isAnalysisMode
                                    ? null
                                    : _showLoadFenDialog,
                                icon: const Icon(Icons.input),
                                label: const Text('FEN laden'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
