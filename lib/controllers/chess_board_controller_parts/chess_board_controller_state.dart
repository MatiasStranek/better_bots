part of chess_board_controller;

BoardHighlights _controllerHighlights(ChessBoardController controller) {
  final analysisSession = controller._analysisSession;

  if (analysisSession != null) {
    return BoardHighlights(
      selectedSquare: controller._selectedSquare,
      lastFrom: analysisSession.lastFrom,
      lastTo: analysisSession.lastTo,
      legalTargets: _controllerLegalTargetsForSelectedSquare(controller),
    );
  }

  return BoardHighlights(
    selectedSquare: controller._selectedSquare,
    lastFrom: controller._lastFrom,
    lastTo: controller._lastTo,
    premoveSquares: controller._premoves.highlightedSquares,
    legalTargets: _controllerLegalTargetsForSelectedSquare(controller),
  );
}

String _controllerStatusText(ChessBoardController controller) {
  final analysisSession = controller._analysisSession;

  if (analysisSession != null) {
    if (analysisSession.analysisGame.in_checkmate) {
      return analysisSession.analysisGame.turn == chess.Color.WHITE
          ? 'Analyse: Schachmatt. Schwarz gewinnt.'
          : 'Analyse: Schachmatt. Weiß gewinnt.';
    }

    if (analysisSession.analysisGame.in_stalemate) {
      return 'Analyse: Patt.';
    }

    if (analysisSession.analysisGame.in_draw) {
      return 'Analyse: Remis.';
    }

    if (analysisSession.analysisGame.in_check) {
      return analysisSession.analysisGame.turn == chess.Color.WHITE
          ? 'Analyse: Weiß ist im Schach.'
          : 'Analyse: Schwarz ist im Schach.';
    }

    if (!analysisSession.hasCompletedLinesForCurrentFen(
      targetDepth: _analysisDepth,
    )) {
      return _controllerAnalysisDepthStatus(analysisSession);
    }

    if (analysisSession.statusText.isNotEmpty) {
      return analysisSession.statusText;
    }

    return 'Analysemodus — ${analysisSession.sideToMoveText} am Zug.';
  }

  if (controller._isBotThinking) {
    if (controller._premoves.isNotEmpty) {
      return 'Bot denkt... Premoves gesetzt: '
          '${controller._premoves.displayText}';
    }

    return 'Bot denkt...';
  }

  if (controller._game.in_checkmate) {
    return controller._game.turn == chess.Color.WHITE
        ? 'Schachmatt. Schwarz gewinnt.'
        : 'Schachmatt. Weiß gewinnt.';
  }

  if (controller._game.in_stalemate) {
    return 'Patt.';
  }

  if (controller._game.in_draw) {
    return 'Remis.';
  }

  if (controller._game.in_check) {
    return controller._game.turn == chess.Color.WHITE
        ? 'Weiß ist im Schach.'
        : 'Schwarz ist im Schach.';
  }

  final sideToMove = controller._game.turn == chess.Color.WHITE
      ? 'Weiß'
      : 'Schwarz';

  if (controller.isPlayersTurn) {
    return '$sideToMove am Zug — du bist dran';
  }

  if (controller._premoves.isNotEmpty) {
    return '$sideToMove am Zug — Bot ist dran. '
        'Premoves: ${controller._premoves.displayText}';
  }

  return '$sideToMove am Zug — Bot ist dran';
}

String _controllerAnalysisDepthStatus(AnalysisSession analysisSession) {
  final currentDepth = _maxAnalysisDepth(analysisSession.topLines);

  return '${analysisSession.sideToMoveText} am Zug — Aktuelle Tiefe: $currentDepth';
}

void _controllerNewGame(ChessBoardController controller, PlayerSide side) {
  if (controller.isAnalysisMode) {
    return;
  }

  controller._searchGeneration++;

  controller._analysisUsedDuringCurrentGame = false;
  controller._resultCountedForCurrentGame = false;
  controller._playerSide = side;
  controller._game.reset();
  controller._normalGameStartFen = _defaultStartFen;
  controller._normalGameMoves.clear();
  controller._selectedSquare = null;
  controller._lastFrom = null;
  controller._lastTo = null;
  controller._premoves.clear();

  controller._isBotThinking = false;
  controller._engineOutput = '-';

  controller._openingLogicAllowed = true;
  controller._resolvedRandomOpeningMove = null;

  _controllerResetResolvedRandomPersonalities(controller);
  _controllerResolveRandomPersonalities(controller);

  _controllerRefreshTrainingCounterSnapshot(controller);

  _safeNotify(controller);

  if (controller._playerSide == PlayerSide.black) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }
}

void _controllerSetSkillLevel(ChessBoardController controller, int level) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._skillLevel = level;
  _safeNotify(controller);
}

void _controllerSetStrengthMode(
  ChessBoardController controller,
  EngineStrengthMode mode,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._strengthMode = mode;
  _safeNotify(controller);
}

void _controllerSetUciElo(ChessBoardController controller, int elo) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._uciElo = elo.clamp(1320, 3190).toInt();
  _safeNotify(controller);
}

void _controllerSetCpLossElo(ChessBoardController controller, int elo) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  final rounded = (elo / 100).round() * 100;
  controller._cpLossElo = rounded.clamp(0, 4000).toInt();
  _safeNotify(controller);
}

void _controllerSetCpLossUciSwitchFullMoveNumber(
  ChessBoardController controller,
  int fullMoveNumber,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  const allowedMoves = <int>[6, 11, 16, 21, 26];

  if (!allowedMoves.contains(fullMoveNumber)) {
    return;
  }

  controller._cpLossUciSwitchFullMoveNumber = fullMoveNumber;
  _safeNotify(controller);
}

void _controllerSetBotPersonality(
  ChessBoardController controller,
  BotPersonality personality,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.chessiverse;
  controller._botPersonality = personality;
  _controllerResetResolvedRandomPersonalities(controller);

  if (personality == BotPersonality.random) {
    controller._resolvedRandomPersonality = _randomBotPersonality();
  }

  _safeNotify(controller);
}

void _controllerSetFritz19Personality(
  ChessBoardController controller,
  Fritz19Personality personality,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.fritz19;
  controller._fritz19Personality = personality;
  _controllerResetResolvedRandomPersonalities(controller);

  if (personality == Fritz19Personality.random) {
    controller._resolvedRandomFritz19Personality =
        _randomFritz19Personality();
  }

  _safeNotify(controller);
}

void _controllerSetAllPersonalitiesRandom(
  ChessBoardController controller,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.random;
  _controllerResetResolvedRandomPersonalities(controller);
  _controllerResolveRandomPersonalities(controller);

  _safeNotify(controller);
}

void _controllerSetPersonaCandidateCount(
  ChessBoardController controller,
  int candidateCount,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  controller._personaCandidateCount = candidateCount.clamp(4, 128).toInt();
  _safeNotify(controller);
}

BotPersonalitySource _controllerEffectiveBotPersonalitySource(
  ChessBoardController controller,
) {
  if (controller._botPersonalitySource == BotPersonalitySource.random) {
    controller._resolvedRandomPersonalitySource ??=
        _randomBotPersonalitySource();
    return controller._resolvedRandomPersonalitySource!;
  }

  return controller._botPersonalitySource;
}

BotPersonality _controllerEffectiveBotPersonality(
  ChessBoardController controller,
) {
  final effectiveSource = _controllerEffectiveBotPersonalitySource(controller);

  if (effectiveSource != BotPersonalitySource.chessiverse) {
    return controller._botPersonality == BotPersonality.none
        ? BotPersonality.none
        : BotPersonality.random;
  }

  if (controller._botPersonalitySource == BotPersonalitySource.random ||
      controller._botPersonality == BotPersonality.random) {
    controller._resolvedRandomPersonality ??= _randomBotPersonality();
    return controller._resolvedRandomPersonality!;
  }

  return controller._botPersonality;
}

Fritz19Personality _controllerEffectiveFritz19Personality(
  ChessBoardController controller,
) {
  final effectiveSource = _controllerEffectiveBotPersonalitySource(controller);

  if (effectiveSource != BotPersonalitySource.fritz19) {
    return controller._fritz19Personality;
  }

  if (controller._botPersonalitySource == BotPersonalitySource.random ||
      controller._fritz19Personality == Fritz19Personality.random) {
    controller._resolvedRandomFritz19Personality ??=
        _randomFritz19Personality();
    return controller._resolvedRandomFritz19Personality!;
  }

  return controller._fritz19Personality;
}

String _controllerActivePersonalityLabel(ChessBoardController controller) {
  final effectiveSource = _controllerEffectiveBotPersonalitySource(controller);

  if (controller._botPersonalitySource == BotPersonalitySource.random) {
    if (effectiveSource == BotPersonalitySource.fritz19) {
      return 'Alles Zufällig: Fritz19 '
          '${_controllerEffectiveFritz19Personality(controller).label}';
    }

    return 'Alles Zufällig: '
        '${_controllerEffectiveBotPersonality(controller).label}';
  }

  if (controller._botPersonalitySource == BotPersonalitySource.fritz19) {
    if (controller._fritz19Personality == Fritz19Personality.random) {
      return 'Fritz19 Zufällig: '
          '${_controllerEffectiveFritz19Personality(controller).label}';
    }

    return '${controller._botPersonalitySource.label}: '
        '${controller._fritz19Personality.label}';
  }

  final effectivePersonality = _controllerEffectiveBotPersonality(controller);

  if (controller._botPersonality == BotPersonality.random &&
      effectivePersonality.isConcretePersonality) {
    return 'Zufällig: ${effectivePersonality.label}';
  }

  return controller._botPersonality.label;
}

void _controllerResetResolvedRandomPersonalities(
  ChessBoardController controller,
) {
  controller._resolvedRandomPersonalitySource = null;
  controller._resolvedRandomPersonality = null;
  controller._resolvedRandomFritz19Personality = null;
}

void _controllerResolveRandomPersonalities(ChessBoardController controller) {
  final effectiveSource = _controllerEffectiveBotPersonalitySource(controller);

  if (effectiveSource == BotPersonalitySource.chessiverse) {
    _controllerEffectiveBotPersonality(controller);
  } else if (effectiveSource == BotPersonalitySource.fritz19) {
    _controllerEffectiveFritz19Personality(controller);
  }
}

BotPersonalitySource _randomBotPersonalitySource() {
  final sources = BotPersonalitySource.values
      .where((source) => source != BotPersonalitySource.random)
      .toList();

  sources.shuffle();

  return sources.first;
}

BotPersonality _randomBotPersonality() {
  final personalities = List<BotPersonality>.from(
    BotPersonality.concretePersonalities,
  );

  personalities.shuffle();

  return personalities.first;
}

Fritz19Personality _randomFritz19Personality() {
  final personalities = List<Fritz19Personality>.from(
    Fritz19Personality.concretePersonalities,
  );

  personalities.shuffle();

  return personalities.first;
}

void _controllerSelectSquare(ChessBoardController controller, String square) {
  controller._selectedSquare = square;
  _safeNotify(controller);
}

void _controllerClearSelectedSquare(ChessBoardController controller) {
  controller._selectedSquare = null;
  _safeNotify(controller);
}

bool _isOwnPiece(ChessBoardController controller, chess.Piece piece) {
  final analysisSession = controller._analysisSession;

  if (analysisSession != null) {
    return piece.color == analysisSession.analysisGame.turn;
  }

  return piece.color == controller._game.turn;
}

bool _isPlayerPiece(ChessBoardController controller, chess.Piece piece) {
  final playerColor = controller.playerIsWhite
      ? chess.Color.WHITE
      : chess.Color.BLACK;

  return piece.color == playerColor;
}

void _recordNormalGameMove(
  ChessBoardController controller, {
  required String from,
  required String to,
  String? promotion,
}) {
  if (controller.isAnalysisMode) {
    return;
  }

  final normalizedPromotion = promotion == null || promotion.isEmpty
      ? null
      : promotion.toLowerCase();

  controller._normalGameMoves.add(
    BoardMove(from: from, to: to, promotion: normalizedPromotion),
  );
}

void _resetNormalGameHistoryFromCurrentFen(
  ChessBoardController controller,
  String fen,
) {
  controller._normalGameStartFen = fen;
  controller._normalGameMoves.clear();
}

void _safeNotify(ChessBoardController controller) {
  if (controller._isDisposed) {
    return;
  }

  _controllerMaybeCountCompletedGame(controller);
  _controllerRefreshTrainingCounterSnapshot(controller);
  _controllerPersistCurrentState(controller);

  controller.notifyListeners();
}
