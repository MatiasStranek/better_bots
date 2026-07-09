part of chess_board_controller;

const int _analysisMultiPv = 5;
const int _analysisDepth = 20;

int _effectiveAnalysisMultiPvForFen(String fen) {
  final analysisGame = chess.Chess();

  try {
    final loaded = analysisGame.load(fen);

    if (!loaded) {
      return _analysisMultiPv;
    }
  } catch (_) {
    return _analysisMultiPv;
  }

  final legalMoveCount = analysisGame.moves().length;

  if (legalMoveCount <= 0) {
    return 1;
  }

  return legalMoveCount.clamp(1, _analysisMultiPv).toInt();
}


List<EngineAnalysisLine> _analysisLinesWithDisplayMoves(
  String fen,
  List<EngineAnalysisLine> lines,
) {
  if (lines.isEmpty) {
    return lines;
  }

  final game = chess.Chess();

  try {
    if (!game.load(fen)) {
      return lines;
    }
  } catch (_) {
    return lines;
  }

  return [
    for (final line in lines)
      line.copyWith(
        shortMove: _analysisMoveDisplayFromFenGame(
          game: game,
          fen: fen,
          uciMove: line.uciMove,
        ),
      ),
  ];
}

String _analysisMoveDisplayFromFenGame({
  required chess.Chess game,
  required String fen,
  required String uciMove,
}) {
  if (uciMove.length < 4 || uciMove == '(none)') {
    return uciMove;
  }

  final from = uciMove.substring(0, 2);
  final to = uciMove.substring(2, 4);
  final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : '';
  final piece = game.get(from);

  if (piece == null) {
    return EngineAnalysisLine.fallbackShortMoveFromUci(uciMove);
  }

  final pieceLetter = _analysisPieceLetter(piece);
  final isPawn = pieceLetter.isEmpty;
  final targetPiece = game.get(to);
  final isCapture = targetPiece != null || (isPawn && from[0] != to[0]);
  final suffix = _analysisCheckSuffixAfterMove(
    fen: fen,
    from: from,
    to: to,
    promotion: promotion,
  );

  if (pieceLetter == 'K' && _analysisIsCastlingMove(from: from, to: to)) {
    return '${to[0] == 'g' ? 'O-O' : 'O-O-O'}$suffix';
  }

  final promotionText = promotion.isEmpty ? '' : '=${promotion.toUpperCase()}';

  if (isPawn) {
    final capturePrefix = isCapture ? '${from[0]}x' : '';
    return '$capturePrefix$to$promotionText$suffix';
  }

  final disambiguation = _analysisMoveDisambiguation(
    game: game,
    from: from,
    to: to,
    piece: piece,
  );
  final captureText = isCapture ? 'x' : '';

  return '$pieceLetter$disambiguation$captureText$to$promotionText$suffix';
}

bool _analysisIsCastlingMove({required String from, required String to}) {
  return (from == 'e1' && (to == 'g1' || to == 'c1')) ||
      (from == 'e8' && (to == 'g8' || to == 'c8'));
}

String _analysisMoveDisambiguation({
  required chess.Chess game,
  required String from,
  required String to,
  required chess.Piece piece,
}) {
  final ambiguousFromSquares = <String>[];

  for (final square in _analysisAllSquares()) {
    if (square == from) {
      continue;
    }

    final otherPiece = game.get(square);

    if (otherPiece == null ||
        otherPiece.color != piece.color ||
        _analysisPieceTypeKey(otherPiece) != _analysisPieceTypeKey(piece)) {
      continue;
    }

    if (_analysisCanMoveFromTo(game: game, from: square, to: to)) {
      ambiguousFromSquares.add(square);
    }
  }

  if (ambiguousFromSquares.isEmpty) {
    return '';
  }

  final fromFile = from[0];
  final fromRank = from[1];
  final sameFileExists = ambiguousFromSquares.any((square) => square[0] == fromFile);
  final sameRankExists = ambiguousFromSquares.any((square) => square[1] == fromRank);

  if (!sameFileExists) {
    return fromFile;
  }

  if (!sameRankExists) {
    return fromRank;
  }

  return from;
}

bool _analysisCanMoveFromTo({
  required chess.Chess game,
  required String from,
  required String to,
}) {
  final moves = game.moves({'square': from, 'verbose': true});

  for (final move in moves) {
    if (move is chess.Move) {
      if (move.toAlgebraic == to) {
        return true;
      }
    } else if (move is Map && move['to'] == to) {
      return true;
    }
  }

  return false;
}

String _analysisCheckSuffixAfterMove({
  required String fen,
  required String from,
  required String to,
  required String promotion,
}) {
  final game = chess.Chess();

  try {
    if (!game.load(fen)) {
      return '';
    }
  } catch (_) {
    return '';
  }

  final moveData = <String, String>{'from': from, 'to': to};

  if (promotion.isNotEmpty) {
    moveData['promotion'] = promotion;
  }

  final moved = game.move(moveData);

  if (!moved) {
    return '';
  }

  if (game.in_checkmate) {
    return '#';
  }

  if (game.in_check) {
    return '+';
  }

  return '';
}

Iterable<String> _analysisAllSquares() sync* {
  for (var file = 0; file < 8; file++) {
    for (var rank = 1; rank <= 8; rank++) {
      yield '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';
    }
  }
}

String _analysisPieceLetter(chess.Piece piece) {
  final typeKey = _analysisPieceTypeKey(piece);

  switch (typeKey) {
    case 'n':
      return 'N';
    case 'b':
      return 'B';
    case 'r':
      return 'R';
    case 'q':
      return 'Q';
    case 'k':
      return 'K';
    default:
      return '';
  }
}

String _analysisPieceTypeKey(chess.Piece piece) {
  final typeText = piece.type.toString().toLowerCase();

  if (typeText == 'p' ||
      typeText.endsWith('.p') ||
      typeText.contains('pawn')) {
    return 'p';
  }

  if (typeText == 'n' ||
      typeText.endsWith('.n') ||
      typeText.contains('knight')) {
    return 'n';
  }

  if (typeText == 'b' ||
      typeText.endsWith('.b') ||
      typeText.contains('bishop')) {
    return 'b';
  }

  if (typeText == 'r' ||
      typeText.endsWith('.r') ||
      typeText.contains('rook')) {
    return 'r';
  }

  if (typeText == 'q' ||
      typeText.endsWith('.q') ||
      typeText.contains('queen')) {
    return 'q';
  }

  if (typeText == 'k' ||
      typeText.endsWith('.k') ||
      typeText.contains('king')) {
    return 'k';
  }

  return typeText;
}

void _controllerToggleAnalysisMode(ChessBoardController controller) {
  if (controller._analysisSession == null) {
    if (!controller.canStartAnalysisMode) {
      return;
    }

    _controllerStartAnalysisMode(controller);
    return;
  }

  _controllerStopAnalysisMode(controller);
}

void _controllerStartAnalysisMode(ChessBoardController controller) {
  if (!controller.canStartAnalysisMode) {
    return;
  }

  final initialPly = _controllerCurrentMainLinePly(controller);
  controller._normalReviewPlyBeforeAnalysis = controller._normalReviewPly;
  controller._analysisMainLinePly = initialPly;

  controller._searchGeneration++;
  controller._analysisGeneration++;
  controller._isBotThinking = false;
  controller._selectedSquare = null;
  controller._premoves.clear();

  if (!(controller._game.game_over ||
      controller._game.in_checkmate ||
      controller._game.in_stalemate ||
      controller._game.in_draw)) {
    controller._analysisUsedDuringCurrentGame = true;
  }

  try {
    controller._analysisSession = AnalysisSession(
      startFen: controller._normalGameStartFen,
      initialMoves: controller._normalGameMoves,
      initialPly: initialPly,
    )..statusText = controller._normalGameMoves.isEmpty
        ? 'Analysemodus aktiv. Startposition übernommen.'
        : 'Analysemodus aktiv. Ganze Partie geladen: '
            '${controller._normalGameMoves.length} Halbzüge verfügbar. '
            'Start bei Halbzug $initialPly.';
  } catch (e) {
    controller._analysisSession = null;
    controller._normalReviewPlyBeforeAnalysis = null;
    controller._analysisMainLinePly = null;
    controller._engineOutput = 'Analyse konnte nicht gestartet werden: $e';
    _safeNotify(controller);
    return;
  }

  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);
}

void _controllerStopAnalysisMode(ChessBoardController controller) {
  controller._analysisGeneration++;
  controller._analysisSession = null;
  controller._analysisSearchQueued = false;
  controller._analysisSearchInFlight = false;
  controller._selectedSquare = null;
  controller._premoves.clear();

  controller._normalReviewPly = controller._normalReviewPlyBeforeAnalysis;
  controller._normalReviewPlyBeforeAnalysis = null;
  controller._analysisMainLinePly = null;

  unawaited(controller._analysisEngine.cancelSearch());

  _safeNotify(controller);
}

Future<void> _controllerStepAnalysisBack(
  ChessBoardController controller,
) async {
  final session = controller._analysisSession;

  if (session == null) {
    return;
  }

  final stepped = session.stepBack();

  if (!stepped) {
    return;
  }

  controller._analysisMainLinePly = _clampMainLinePly(
    controller,
    (controller._analysisMainLinePly ?? controller._normalGameMoves.length) - 1,
  );
  controller._selectedSquare = null;
  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);
}


Future<void> _controllerStepAnalysisForward(
  ChessBoardController controller,
) async {
  final session = controller._analysisSession;

  if (session == null) {
    return;
  }

  final stepped = session.stepForward();

  if (!stepped) {
    return;
  }

  controller._analysisMainLinePly = _clampMainLinePly(
    controller,
    (controller._analysisMainLinePly ?? 0) + 1,
  );
  controller._selectedSquare = null;
  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);
}


Future<void> _controllerJumpAnalysisToStart(
  ChessBoardController controller,
) async {
  final session = controller._analysisSession;

  if (session == null) {
    return;
  }

  final jumped = session.jumpToStart();

  if (!jumped) {
    return;
  }

  controller._analysisMainLinePly = 0;
  controller._selectedSquare = null;
  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);
}


Future<void> _controllerJumpAnalysisToEnd(
  ChessBoardController controller,
) async {
  final session = controller._analysisSession;

  if (session == null) {
    return;
  }

  final jumped = session.jumpToEnd();

  if (!jumped) {
    return;
  }

  controller._analysisMainLinePly = controller._normalGameMoves.length;
  controller._selectedSquare = null;
  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);
}


Future<void> _controllerOnAnalysisSquareTap(
  ChessBoardController controller,
  String square,
) async {
  final session = controller._analysisSession;

  if (session == null || session.isGameOver) {
    return;
  }

  final piece = session.pieceAt(square);

  if (controller._selectedSquare == null) {
    if (piece == null || piece.color != session.analysisGame.turn) {
      return;
    }

    _controllerSelectSquare(controller, square);
    return;
  }

  if (controller._selectedSquare == square) {
    _controllerClearSelectedSquare(controller);
    return;
  }

  final from = controller._selectedSquare!;
  final moved = await _controllerTryAnalysisMove(
    controller,
    from: from,
    to: square,
  );

  if (moved) {
    return;
  }

  if (piece != null && piece.color == session.analysisGame.turn) {
    _controllerSelectSquare(controller, square);
    return;
  }

  _controllerClearSelectedSquare(controller);
}

Future<bool> _controllerTryAnalysisMove(
  ChessBoardController controller, {
  required String from,
  required String to,
  String? promotion,
}) async {
  final session = controller._analysisSession;

  if (session == null || session.isGameOver) {
    return false;
  }

  final selectedPromotion = await _promotionForAnalysisMoveIfNeeded(
    controller,
    from: from,
    to: to,
    promotion: promotion,
  );

  if (selectedPromotion == null) {
    _controllerClearSelectedSquare(controller);
    return false;
  }

  final moved = session.playMove(
    from: from,
    to: to,
    promotion: selectedPromotion.isEmpty ? null : selectedPromotion,
  );

  if (!moved) {
    return false;
  }

  controller._selectedSquare = null;

  _safeNotify(controller);
  _requestAnalysisForCurrentPosition(controller);

  return true;
}

Future<String?> _promotionForAnalysisMoveIfNeeded(
  ChessBoardController controller, {
  required String from,
  required String to,
  String? promotion,
}) async {
  final session = controller._analysisSession;

  if (session == null) {
    return null;
  }

  final piece = session.pieceAt(from);

  if (piece == null || !_isPawn(piece)) {
    return '';
  }

  final targetRank = to.substring(1, 2);
  final isPromotion = piece.color == chess.Color.WHITE
      ? targetRank == '8'
      : targetRank == '1';

  if (!isPromotion) {
    return '';
  }

  if (promotion != null && promotion.isNotEmpty) {
    return _normalizePromotion(promotion);
  }

  if (controller._onPromotionChoiceRequested == null) {
    return 'q';
  }

  final choice = await controller._onPromotionChoiceRequested!(
    from: from,
    to: to,
    playerSide: piece.color == chess.Color.WHITE
        ? PlayerSide.white
        : PlayerSide.black,
  );

  if (choice == null || choice.isEmpty) {
    return null;
  }

  return _normalizePromotion(choice);
}

void _requestAnalysisForCurrentPosition(ChessBoardController controller) {
  final session = controller._analysisSession;

  if (session == null || controller._isDisposed) {
    return;
  }

  controller._analysisGeneration++;

  if (session.hasCompletedLinesForCurrentFen(targetDepth: _analysisDepth)) {
    session
      ..isAnalyzing = false
      ..statusText = 'Gespeicherte Tiefe-20-Analyse geladen.';
    _safeNotify(controller);
    return;
  }

  session
    ..isAnalyzing = true
    ..statusText = 'Analyse läuft für ${session.sideToMoveText} am Zug...';
  _safeNotify(controller);

  if (controller._analysisSearchInFlight) {
    controller._analysisSearchQueued = true;
    unawaited(controller._analysisEngine.cancelSearch());
    return;
  }

  unawaited(_runQueuedAnalysis(controller));
}

Future<void> _runQueuedAnalysis(ChessBoardController controller) async {
  controller._analysisSearchInFlight = true;

  try {
    while (!controller._isDisposed) {
      final session = controller._analysisSession;

      if (session == null) {
        return;
      }

      if (session.hasCompletedLinesForCurrentFen(targetDepth: _analysisDepth)) {
        session
          ..isAnalyzing = false
          ..statusText = 'Gespeicherte Tiefe-20-Analyse geladen.';
        _safeNotify(controller);
        return;
      }

      controller._analysisSearchQueued = false;
      final generation = controller._analysisGeneration;
      final fen = session.fen;
      final effectiveMultiPv = _effectiveAnalysisMultiPvForFen(fen);

      try {
        final lines = await controller._analysisEngine.analyzePositionFromFen(
          fen: fen,
          multiPv: effectiveMultiPv,
          depth: _analysisDepth,
          onUpdate: (liveLines) {
            final currentSession = controller._analysisSession;

            if (currentSession == null ||
                !identical(currentSession, session) ||
                currentSession.fen != fen ||
                generation != controller._analysisGeneration ||
                controller._isDisposed) {
              return;
            }

            currentSession.updateLiveTopLinesForFen(
              fen: fen,
              lines: _analysisLinesWithDisplayMoves(fen, liveLines),
              targetDepth: _analysisDepth,
            );

            final maxDepth = _maxAnalysisDepth(currentSession.topLines);
            currentSession.statusText = currentSession
                    .hasCompletedLinesForCurrentFen(targetDepth: _analysisDepth)
                ? 'Tiefe $_analysisDepth erreicht und gespeichert.'
                : 'Analyse läuft: aktuelle Tiefe $maxDepth/$_analysisDepth.';

            _safeNotify(controller);
          },
        );

        final currentSession = controller._analysisSession;

        if (currentSession == null ||
            !identical(currentSession, session) ||
            currentSession.fen != fen ||
            generation != controller._analysisGeneration ||
            controller._isDisposed) {
          if (!controller._analysisSearchQueued) {
            return;
          }
          continue;
        }

        final displayLines = _analysisLinesWithDisplayMoves(fen, lines);

        session.updateCompletedTopLinesForFen(
          fen: fen,
          lines: displayLines,
          targetDepth: _analysisDepth,
        );

        final hasCompletedLines = session.hasCompletedLinesForCurrentFen(
          targetDepth: _analysisDepth,
        );

        session
          ..statusText = displayLines.isEmpty
              ? 'Analyse aktiv. Keine Engine-Linie verfügbar.'
              : hasCompletedLines
                  ? 'Analyse aktiv. Tiefe $_analysisDepth gespeichert.'
                  : 'Analyse aktiv. ${displayLines.length} Linien bis Tiefe ${_maxAnalysisDepth(displayLines)}.'
          ..isAnalyzing = false;

        _safeNotify(controller);
      } catch (e) {
        final currentSession = controller._analysisSession;

        if (currentSession == null ||
            !identical(currentSession, session) ||
            currentSession.fen != fen ||
            generation != controller._analysisGeneration ||
            controller._isDisposed) {
          if (!controller._analysisSearchQueued) {
            return;
          }
          continue;
        }

        session
          ..isAnalyzing = false
          ..statusText = 'Analysefehler: $e';

        _safeNotify(controller);
      }

      if (!controller._analysisSearchQueued) {
        return;
      }

      final queuedSession = controller._analysisSession;
      if (queuedSession != null) {
        if (queuedSession.hasCompletedLinesForCurrentFen(
          targetDepth: _analysisDepth,
        )) {
          queuedSession
            ..isAnalyzing = false
            ..statusText = 'Gespeicherte Tiefe-20-Analyse geladen.';
        } else {
          queuedSession
            ..isAnalyzing = true
            ..statusText =
                'Analyse läuft für ${queuedSession.sideToMoveText} am Zug...';
        }

        _safeNotify(controller);
      }
    }
  } finally {
    controller._analysisSearchInFlight = false;

    final session = controller._analysisSession;
    if (session != null && !controller._analysisSearchQueued) {
      session.isAnalyzing = false;
      _safeNotify(controller);
    }
  }
}

int _maxAnalysisDepth(List<EngineAnalysisLine> lines) {
  var maxDepth = 0;

  for (final line in lines) {
    if (line.depth > maxDepth) {
      maxDepth = line.depth;
    }
  }

  return maxDepth;
}
