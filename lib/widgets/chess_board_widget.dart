import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/chess_board_controller.dart';
import '../models/board_annotation.dart';
import '../models/player_side.dart';
import 'chess_board/chess_board_controls.dart';
import 'chess_board/chess_board_debug_panel.dart';
import 'chess_board/chess_board_grid.dart';
import 'chess_board/chess_status_text.dart';
import 'chess_move_list_panel.dart';
import 'chess_result_stats_panel.dart';

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
  final Map<String, Set<String>> _analysisAnnotationMarkedSquaresByFen =
      <String, Set<String>>{};
  final Map<String, Set<BoardArrowAnnotation>> _analysisAnnotationArrowsByFen =
      <String, Set<BoardArrowAnnotation>>{};

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

  String get _analysisAnnotationPositionKey => _controller.fen.trim();

  Set<String> get _activeAnnotationMarkedSquares {
    if (!_controller.isAnalysisMode) {
      return _normalAnnotationMarkedSquares;
    }

    return _analysisAnnotationMarkedSquaresByFen[_analysisAnnotationPositionKey] ??
        const <String>{};
  }

  Set<BoardArrowAnnotation> get _activeAnnotationArrows {
    if (!_controller.isAnalysisMode) {
      return _normalAnnotationArrows;
    }

    return _analysisAnnotationArrowsByFen[_analysisAnnotationPositionKey] ??
        const <BoardArrowAnnotation>{};
  }

  void _handleControllerChanged() {
    final isAnalysisMode = _controller.isAnalysisMode;
    final hasJustLeftAnalysisMode = _lastKnownAnalysisMode && !isAnalysisMode;

    _lastKnownAnalysisMode = isAnalysisMode;

    if (!hasJustLeftAnalysisMode ||
        (_analysisAnnotationMarkedSquaresByFen.isEmpty &&
            _analysisAnnotationArrowsByFen.isEmpty)) {
      return;
    }

    if (!mounted) {
      _analysisAnnotationMarkedSquaresByFen.clear();
      _analysisAnnotationArrowsByFen.clear();
      return;
    }

    setState(() {
      _analysisAnnotationMarkedSquaresByFen.clear();
      _analysisAnnotationArrowsByFen.clear();
    });
  }

  void _clearBoardAnnotations() {
    if (_controller.isAnalysisMode) {
      final positionKey = _analysisAnnotationPositionKey;
      final markedSquares = _analysisAnnotationMarkedSquaresByFen[positionKey];
      final arrows = _analysisAnnotationArrowsByFen[positionKey];

      if ((markedSquares == null || markedSquares.isEmpty) &&
          (arrows == null || arrows.isEmpty)) {
        return;
      }

      setState(() {
        _analysisAnnotationMarkedSquaresByFen.remove(positionKey);
        _analysisAnnotationArrowsByFen.remove(positionKey);
      });
      return;
    }

    if (_normalAnnotationMarkedSquares.isEmpty &&
        _normalAnnotationArrows.isEmpty) {
      return;
    }

    setState(() {
      _normalAnnotationMarkedSquares.clear();
      _normalAnnotationArrows.clear();
    });
  }

  void _toggleAnnotationSquare(String square) {
    if (_controller.isAnalysisMode) {
      final positionKey = _analysisAnnotationPositionKey;

      setState(() {
        final markedSquares = _analysisAnnotationMarkedSquaresByFen.putIfAbsent(
          positionKey,
          () => <String>{},
        );

        if (!markedSquares.add(square)) {
          markedSquares.remove(square);
        }

        if (markedSquares.isEmpty) {
          _analysisAnnotationMarkedSquaresByFen.remove(positionKey);
        }
      });
      return;
    }

    setState(() {
      if (!_normalAnnotationMarkedSquares.add(square)) {
        _normalAnnotationMarkedSquares.remove(square);
      }
    });
  }

  void _toggleAnnotationArrow(BoardArrowAnnotation arrow) {
    if (_controller.isAnalysisMode) {
      final positionKey = _analysisAnnotationPositionKey;

      setState(() {
        final arrows = _analysisAnnotationArrowsByFen.putIfAbsent(
          positionKey,
          () => <BoardArrowAnnotation>{},
        );

        if (!arrows.add(arrow)) {
          arrows.remove(arrow);
        }

        if (arrows.isEmpty) {
          _analysisAnnotationArrowsByFen.remove(positionKey);
        }
      });
      return;
    }

    setState(() {
      if (!_normalAnnotationArrows.add(arrow)) {
        _normalAnnotationArrows.remove(arrow);
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
          title: const Text(
            'Bauernumwandlung',
            style: _dialogTitleTextStyle,
          ),
          contentTextStyle: const TextStyle(color: Colors.black87),
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
            title: const Text(
              'FEN laden',
              style: _dialogTitleTextStyle,
            ),
            contentTextStyle: const TextStyle(color: Colors.black87),
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
                style: TextButton.styleFrom(
                  foregroundColor: _dialogAccentBlue,
                ),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(fenController.text);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: _dialogAccentBlue,
                ),
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

  bool _isTextInputFocused() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;

    if (focusedContext == null) {
      return false;
    }

    return focusedContext.widget is EditableText ||
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  Future<void> _handleBoardBackButton() async {
    if (_controller.isAnalysisMode) {
      await _controller.stepAnalysisBack();
      return;
    }

    _controller.stepMainLineBack();
  }

  Future<void> _handleBoardForwardButton() async {
    if (_controller.isAnalysisMode) {
      await _controller.stepAnalysisForward();
      return;
    }

    _controller.stepMainLineForward();
  }

  Future<void> _handleBoardBackToStartButton() async {
    if (_controller.isAnalysisMode) {
      await _controller.jumpAnalysisToStart();
      return;
    }

    _controller.jumpMainLineToStart();
  }

  Future<void> _handleBoardForwardToEndButton() async {
    if (_controller.isAnalysisMode) {
      await _controller.jumpAnalysisToEnd();
      return;
    }

    _controller.jumpMainLineToEnd();
  }


  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_isTextInputFocused()) {
      return KeyEventResult.ignored;
    }

    if (_controller.isAnalysisMode) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _controller.stepAnalysisBack();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _controller.stepAnalysisForward();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _controller.toggleAnalysisMode();
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_controller.canNavigateMainLineBack) {
        _controller.stepMainLineBack();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_controller.canNavigateMainLineForward) {
        _controller.stepMainLineForward();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_controller.canStartAnalysisMode) {
        _controller.toggleAnalysisMode();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _controller.restartTrainingCounterGame();
      } else {
        _controller.restartGame();
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      _controller.newGame(PlayerSide.white);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyB) {
      _controller.newGame(PlayerSide.black);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = _darkBackgroundTheme(theme);

    return Theme(
      data: appTheme,
      child: DefaultTextStyle(
        style: appTheme.textTheme.bodyMedium ?? const TextStyle(),
        child: IconTheme(
          data: const IconThemeData(color: _lightBlueForeground),
          child: KeyboardListener(
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
                      effectiveBotOpeningMove:
                          _controller.effectiveBotOpeningMove,
                      selectedOpeningMoves:
                          _controller.selectedOpeningMoves,
                      botPersonalitySource: _controller.botPersonalitySource,
                      effectiveBotPersonalitySource:
                          _controller.effectiveBotPersonalitySource,
                      botPersonality: _controller.botPersonality,
                      effectiveBotPersonality:
                          _controller.effectiveBotPersonality,
                      fritz19Personality: _controller.fritz19Personality,
                      effectiveFritz19Personality:
                          _controller.effectiveFritz19Personality,
                      selectedChessiversePersonalities:
                          _controller.selectedChessiversePersonalities,
                      selectedFritz19Personalities:
                          _controller.selectedFritz19Personalities,
                      personaCandidateCount: _controller.personaCandidateCount,
                      isBotThinking: _controller.isBotThinking,
                      isAnalysisMode: _controller.isAnalysisMode,
                      canToggleAnalysisMode: _controller.canToggleAnalysisMode,
                      canNavigateAnalysisBack: _controller.isAnalysisMode
                          ? _controller.canNavigateAnalysisBack
                          : _controller.canNavigateMainLineBack,
                      canNavigateAnalysisForward: _controller.isAnalysisMode
                          ? _controller.canNavigateAnalysisForward
                          : _controller.canNavigateMainLineForward,
                      onNewGame: _controller.newGame,
                      onRestart: _controller.restartGame,
                      onToggleAnalysisMode: _controller.toggleAnalysisMode,
                      onAnalysisBack: _handleBoardBackButton,
                      onAnalysisForward: _handleBoardForwardButton,
                      onAnalysisBackToStart: _handleBoardBackToStartButton,
                      onAnalysisForwardToEnd: _handleBoardForwardToEndButton,
                      onSkillLevelChanged: _controller.setSkillLevel,
                      onUciEloChanged: _controller.setUciElo,
                      onCpLossEloChanged: _controller.setCpLossElo,
                      onCpLossUciSwitchFullMoveNumberChanged:
                          _controller.setCpLossUciSwitchFullMoveNumber,
                      onStrengthModeChanged: _controller.setStrengthMode,
                      onBotOpeningMoveChanged: _controller.setBotOpeningMove,
                      onOpeningMoveSelectionToggled:
                          _controller.toggleOpeningMoveSelection,
                      onOpeningMoveSelectionCleared:
                          _controller.clearOpeningMoveSelection,
                      onBotPersonalityChanged: _controller.setBotPersonality,
                      onFritz19PersonalityChanged:
                          _controller.setFritz19Personality,
                      onChessiversePersonalitySelectionToggled:
                          _controller.toggleChessiversePersonalitySelection,
                      onFritz19PersonalitySelectionToggled:
                          _controller.toggleFritz19PersonalitySelection,
                      onPersonalitySelectionCleared:
                          _controller.clearPersonalitySelection,
                      onAllPersonalitiesRandomChanged:
                          _controller.setAllPersonalitiesRandom,
                      onPersonaCandidateCountChanged:
                          _controller.setPersonaCandidateCount,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChessBoardGrid(
                          playerIsWhite: _controller.playerIsWhite,
                          fen: _controller.fen,
                          isAnalysisMode: _controller.isAnalysisMode,
                          isAnalysisBranchActive:
                              _controller.isAnalysisBranchActive,
                          highlights: _controller.highlights,
                          pieceAt: _controller.pieceAt,
                          canHumanMovePiece: _controller.canHumanMovePiece,
                          canMoveTo: _controller.canMoveTo,
                          legalTargetsFromSquare:
                              _controller.legalTargetsFromSquare,
                          onSquareTap: _controller.onSquareTap,
                          onMove: _controller.tryHumanMove,
                          onPieceDragStarted: _controller.selectSquare,
                          onPieceDragEnded: _controller.clearSelectedSquare,
                          annotationModeEnabled: true,
                          annotationMarkedSquares:
                              _activeAnnotationMarkedSquares,
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
                                  isAnalysisThinking:
                                      _controller.isAnalysisThinking,
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
                                    OutlinedButton.icon(
                                      onPressed: _controller.isAnalysisMode
                                          ? null
                                          : _controller.restartTrainingCounterGame,
                                      icon: const Icon(Icons.restart_alt),
                                      label: const Text('Neustart Zähler'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ChessResultStatsTextView(
                                  counter: _controller.trainingCounterSnapshot,
                                  analysisUsedDuringCurrentGame:
                                      _controller.analysisUsedDuringCurrentGame,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          height: 640,
                          child: ChessMoveListPanel(
                            entries: _controller.mainLineMoveEntries,
                            selectedPly: _controller.currentMainLinePly,
                            isReviewMode: _controller.isNormalReviewMode,
                            isAnalysisMode: _controller.isAnalysisMode,
                            onMoveSelected: _controller.jumpToMainLinePly,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

const Color _lightBlueForeground = Color(0xFFAEDBFF);
const Color _dialogAccentBlue = Color(0xFF2E5F93);
const TextStyle _dialogTitleTextStyle = TextStyle(color: Colors.black);
const Color _enabledButtonBackground = Color(0xF2FFFFFF);
const Color _disabledButtonBackground = Color(0x22FFFFFF);
const Color _disabledButtonForeground = Color(0xFF8D95A3);

ThemeData _darkBackgroundTheme(ThemeData baseTheme) {
  final colorScheme = baseTheme.colorScheme.copyWith(
    primary: _lightBlueForeground,
    onPrimary: _lightBlueForeground,
    onSurface: Colors.white,
    surface: Colors.white,
  );

  return baseTheme.copyWith(
    colorScheme: colorScheme,
    textTheme: _whiteTextTheme(baseTheme.textTheme),
    iconTheme: baseTheme.iconTheme.copyWith(color: _lightBlueForeground),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _filledButtonStyleWithClickCursor(
        baseTheme.elevatedButtonTheme.style,
        baseTheme.colorScheme.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _outlinedButtonStyleWithClickCursor(
        baseTheme.outlinedButtonTheme.style,
        _lightBlueForeground,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _textButtonStyleWithClickCursor(
        baseTheme.textButtonTheme.style,
        baseTheme.colorScheme.primary,
      ),
    ),
  );
}

TextTheme _whiteTextTheme(TextTheme textTheme) {
  TextStyle? makeWhite(TextStyle? style) {
    return style?.copyWith(color: Colors.white, shadows: const <Shadow>[]);
  }

  return textTheme.copyWith(
    displayLarge: makeWhite(textTheme.displayLarge),
    displayMedium: makeWhite(textTheme.displayMedium),
    displaySmall: makeWhite(textTheme.displaySmall),
    headlineLarge: makeWhite(textTheme.headlineLarge),
    headlineMedium: makeWhite(textTheme.headlineMedium),
    headlineSmall: makeWhite(textTheme.headlineSmall),
    titleLarge: makeWhite(textTheme.titleLarge),
    titleMedium: makeWhite(textTheme.titleMedium),
    titleSmall: makeWhite(textTheme.titleSmall),
    bodyLarge: makeWhite(textTheme.bodyLarge),
    bodyMedium: makeWhite(textTheme.bodyMedium),
    bodySmall: makeWhite(textTheme.bodySmall),
    labelLarge: makeWhite(textTheme.labelLarge),
    labelMedium: makeWhite(textTheme.labelMedium),
    labelSmall: makeWhite(textTheme.labelSmall),
  );
}

ButtonStyle _filledButtonStyleWithClickCursor(
  ButtonStyle? baseStyle,
  Color buttonForeground,
) {
  return _buttonStyleWithClickCursor(baseStyle).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _disabledButtonForeground;
      }

      return buttonForeground;
    }),
    iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _disabledButtonForeground;
      }

      return buttonForeground;
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _disabledButtonBackground;
      }

      return _enabledButtonBackground;
    }),
    shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
  );
}

ButtonStyle _outlinedButtonStyleWithClickCursor(
  ButtonStyle? baseStyle,
  Color buttonForeground,
) {
  return _buttonStyleWithClickCursor(baseStyle).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _disabledButtonForeground;
      }

      return buttonForeground;
    }),
    iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return _disabledButtonForeground;
      }

      return buttonForeground;
    }),
    side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: _disabledButtonForeground.withAlpha(100));
      }

      return BorderSide(color: buttonForeground.withAlpha(210));
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.white.withAlpha(12);
      }

      return Colors.white.withAlpha(16);
    }),
  );
}

ButtonStyle _textButtonStyleWithClickCursor(
  ButtonStyle? baseStyle,
  Color buttonForeground,
) {
  return _buttonStyleWithClickCursor(baseStyle).copyWith(
    foregroundColor: WidgetStatePropertyAll<Color>(buttonForeground),
    iconColor: WidgetStatePropertyAll<Color>(buttonForeground),
  );
}

ButtonStyle _buttonStyleWithClickCursor(ButtonStyle? baseStyle) {
  return (baseStyle ?? const ButtonStyle()).copyWith(
    mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return SystemMouseCursors.basic;
      }

      return SystemMouseCursors.click;
    }),
  );
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
      style: OutlinedButton.styleFrom(
        foregroundColor: _dialogAccentBlue,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

