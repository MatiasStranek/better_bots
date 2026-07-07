part of chess_board_controller;

const int _analysisMultiPv = 5;
const int _analysisDepth = 20;

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

  controller._searchGeneration++;
  controller._analysisGeneration++;
  controller._isBotThinking = false;
  controller._selectedSquare = null;
  controller._premoves.clear();

  if (!controller.isGameOver) {
    controller._analysisUsedDuringCurrentGame = true;
  }

  try {
    controller._analysisSession = AnalysisSession(
      startFen: controller._normalGameStartFen,
      initialMoves: controller._normalGameMoves,
      initialPly: controller._normalGameMoves.length,
    )..statusText = controller._normalGameMoves.isEmpty
        ? 'Analysemodus aktiv. Startposition übernommen.'
        : 'Analysemodus aktiv. Ganze Partie geladen: '
            '${controller._normalGameMoves.length} Halbzüge verfügbar.';
  } catch (e) {
    controller._analysisSession = null;
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

      try {
        final lines = await controller._analysisEngine.analyzePositionFromFen(
          fen: fen,
          multiPv: _analysisMultiPv,
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
              lines: liveLines,
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

        session.updateCompletedTopLinesForFen(
          fen: fen,
          lines: lines,
          targetDepth: _analysisDepth,
        );

        final hasCompletedLines = session.hasCompletedLinesForCurrentFen(
          targetDepth: _analysisDepth,
        );

        session
          ..statusText = lines.isEmpty
              ? 'Analyse aktiv. Keine Engine-Linie verfügbar.'
              : hasCompletedLines
                  ? 'Analyse aktiv. Tiefe $_analysisDepth gespeichert.'
                  : 'Analyse aktiv. ${lines.length} Linien bis Tiefe ${_maxAnalysisDepth(lines)}.'
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