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

  if (_controllerIsNormalReviewMode(controller)) {
    final lastMove = _controllerLastDisplayedNormalMove(controller);

    return BoardHighlights(
      selectedSquare: null,
      lastFrom: lastMove?.from,
      lastTo: lastMove?.to,
      legalTargets: const [],
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

  if (_controllerIsNormalReviewMode(controller)) {
    final currentPly = _controllerCurrentMainLinePly(controller);
    final totalPly = controller._normalGameMoves.length;
    final displayGame = _controllerDisplayedNormalGame(controller);
    final sideToMove = displayGame.turn == chess.Color.WHITE
        ? 'Weiß'
        : 'Schwarz';

    return 'Rückblick: Halbzug $currentPly/$totalPly — '
        '$sideToMove am Zug. Züge sind gesperrt.';
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

  _controllerApplyPendingBotSettings(controller);

  controller._analysisUsedDuringCurrentGame = false;
  controller._resultCountedForCurrentGame = false;
  controller._playerSide = side;
  controller._game.reset();
  controller._normalGameStartFen = _defaultStartFen;
  controller._normalGameMoves.clear();
  _controllerClearNormalReview(controller);
  controller._selectedSquare = null;
  controller._lastFrom = null;
  controller._lastTo = null;
  controller._premoves.clear();

  controller._isBotThinking = false;
  controller._engineOutput = '-';

  controller._openingLogicAllowed = true;
  _controllerResetResolvedOpeningMove(controller);
  _controllerResolveRandomOpeningMove(controller);

  _controllerResetResolvedRandomPersonalities(controller);
  _controllerResolveRandomPersonalities(controller);

  _controllerRefreshTrainingCounterSnapshot(controller);

  _safeNotify(controller);

  if (controller._playerSide == PlayerSide.black) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }
}

void _controllerSetBotOpeningMove(
  ChessBoardController controller,
  BotOpeningMove openingMove,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingSetBotOpeningMove(settings, openingMove),
    );
    return;
  }

  controller._botOpeningMove = openingMove;
  controller._selectedOpeningMoves.clear();
  _controllerResetResolvedOpeningMove(controller);
  _controllerResolveRandomOpeningMove(controller);
  controller._openingLogicAllowed = true;

  _safeNotify(controller);
}

void _controllerToggleOpeningMoveSelection(
  ChessBoardController controller,
  BotOpeningMove openingMove,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingToggleOpeningMoveSelection(settings, openingMove),
    );
    return;
  }

  if (!openingMove.isRealOpening) {
    _controllerSetBotOpeningMove(controller, openingMove);
    return;
  }

  if (controller._selectedOpeningMoves.isEmpty &&
      controller._botOpeningMove.isRealOpening) {
    controller._selectedOpeningMoves.add(controller._botOpeningMove);
  }

  if (controller._selectedOpeningMoves.contains(openingMove)) {
    controller._selectedOpeningMoves.remove(openingMove);
  } else {
    controller._selectedOpeningMoves.add(openingMove);
  }

  _controllerApplyOpeningSelection(controller);
  _safeNotify(controller);
}

void _controllerClearOpeningMoveSelection(
  ChessBoardController controller,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      _pendingClearOpeningMoveSelection,
    );
    return;
  }

  controller._selectedOpeningMoves.clear();
  controller._botOpeningMove = BotOpeningMove.none;
  _controllerResetResolvedOpeningMove(controller);
  controller._openingLogicAllowed = true;

  _safeNotify(controller);
}

void _controllerApplyOpeningSelection(ChessBoardController controller) {
  _controllerResetResolvedOpeningMove(controller);

  if (controller._selectedOpeningMoves.isEmpty) {
    controller._botOpeningMove = BotOpeningMove.none;
  } else if (controller._selectedOpeningMoves.length == 1) {
    controller._botOpeningMove = controller._selectedOpeningMoves.first;
  } else {
    controller._botOpeningMove = BotOpeningMove.random;
    _controllerResolveRandomOpeningMove(controller);
  }

  controller._openingLogicAllowed = true;
}

void _controllerResetResolvedOpeningMove(ChessBoardController controller) {
  controller._resolvedRandomOpeningMove = null;
}

void _controllerResolveRandomOpeningMove(ChessBoardController controller) {
  if (controller._botOpeningMove == BotOpeningMove.random) {
    _resolveSelectedOpening(controller);
  }
}

bool _controllerShouldQueueBotSettings(ChessBoardController controller) {
  if (controller.isAnalysisMode) {
    return false;
  }

  if (controller._normalGameMoves.isNotEmpty) {
    return true;
  }

  return controller._game.fen != _defaultStartFen;
}

_PendingBotSettings _controllerMutablePendingBotSettings(
  ChessBoardController controller,
) {
  return controller._pendingBotSettings ??=
      _PendingBotSettings.fromController(controller);
}

void _controllerApplyPendingBotSettings(ChessBoardController controller) {
  final pendingBotSettings = controller._pendingBotSettings;

  if (pendingBotSettings == null) {
    return;
  }

  pendingBotSettings.applyTo(controller);
  controller._pendingBotSettings = null;
}

void _queueBotSettingsChange(
  ChessBoardController controller,
  void Function(_PendingBotSettings settings) update,
) {
  final settings = _controllerMutablePendingBotSettings(controller);

  update(settings);

  _safeNotify(controller);
}

class _PendingBotSettings {
  _PendingBotSettings({
    required this.skillLevel,
    required this.strengthMode,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
    required this.botOpeningMove,
    required List<BotOpeningMove> selectedOpeningMoves,
    required this.botPersonalitySource,
    required this.botPersonality,
    required this.fritz19Personality,
    required List<BotPersonality> selectedChessiversePersonalities,
    required List<Fritz19Personality> selectedFritz19Personalities,
    required this.personaCandidateCount,
  })  : selectedOpeningMoves = List<BotOpeningMove>.from(selectedOpeningMoves),
        selectedChessiversePersonalities =
            List<BotPersonality>.from(selectedChessiversePersonalities),
        selectedFritz19Personalities =
            List<Fritz19Personality>.from(selectedFritz19Personalities);

  factory _PendingBotSettings.fromController(
    ChessBoardController controller,
  ) {
    return _PendingBotSettings(
      skillLevel: controller._skillLevel,
      strengthMode: controller._strengthMode,
      uciElo: controller._uciElo,
      cpLossElo: controller._cpLossElo,
      cpLossUciSwitchFullMoveNumber:
          controller._cpLossUciSwitchFullMoveNumber,
      botOpeningMove: controller._botOpeningMove,
      selectedOpeningMoves: controller._selectedOpeningMoves,
      botPersonalitySource: controller._botPersonalitySource,
      botPersonality: controller._botPersonality,
      fritz19Personality: controller._fritz19Personality,
      selectedChessiversePersonalities:
          controller._selectedChessiversePersonalities,
      selectedFritz19Personalities: controller._selectedFritz19Personalities,
      personaCandidateCount: controller._personaCandidateCount,
    );
  }

  int skillLevel;
  EngineStrengthMode strengthMode;
  int uciElo;
  int cpLossElo;
  int cpLossUciSwitchFullMoveNumber;

  BotOpeningMove botOpeningMove;
  final List<BotOpeningMove> selectedOpeningMoves;

  BotPersonalitySource botPersonalitySource;
  BotPersonality botPersonality;
  Fritz19Personality fritz19Personality;
  final List<BotPersonality> selectedChessiversePersonalities;
  final List<Fritz19Personality> selectedFritz19Personalities;

  int personaCandidateCount;

  void applyTo(ChessBoardController controller) {
    controller
      .._skillLevel = skillLevel
      .._strengthMode = strengthMode
      .._uciElo = uciElo
      .._cpLossElo = cpLossElo
      .._cpLossUciSwitchFullMoveNumber = cpLossUciSwitchFullMoveNumber
      .._botOpeningMove = botOpeningMove
      .._botPersonalitySource = botPersonalitySource
      .._botPersonality = botPersonality
      .._fritz19Personality = fritz19Personality
      .._personaCandidateCount = personaCandidateCount;

    controller._selectedOpeningMoves
      ..clear()
      ..addAll(selectedOpeningMoves);

    controller._selectedChessiversePersonalities
      ..clear()
      ..addAll(selectedChessiversePersonalities);

    controller._selectedFritz19Personalities
      ..clear()
      ..addAll(selectedFritz19Personalities);

    controller._resolvedRandomOpeningMove = null;
    controller._resolvedRandomPersonalitySource = null;
    controller._resolvedRandomPersonality = null;
    controller._resolvedRandomFritz19Personality = null;
  }
}

void _pendingSetBotOpeningMove(
  _PendingBotSettings settings,
  BotOpeningMove openingMove,
) {
  settings.botOpeningMove = openingMove;
  settings.selectedOpeningMoves.clear();
}

void _pendingToggleOpeningMoveSelection(
  _PendingBotSettings settings,
  BotOpeningMove openingMove,
) {
  if (!openingMove.isRealOpening) {
    _pendingSetBotOpeningMove(settings, openingMove);
    return;
  }

  if (settings.selectedOpeningMoves.isEmpty &&
      settings.botOpeningMove.isRealOpening) {
    settings.selectedOpeningMoves.add(settings.botOpeningMove);
  }

  if (settings.selectedOpeningMoves.contains(openingMove)) {
    settings.selectedOpeningMoves.remove(openingMove);
  } else {
    settings.selectedOpeningMoves.add(openingMove);
  }

  _pendingApplyOpeningSelection(settings);
}

void _pendingClearOpeningMoveSelection(_PendingBotSettings settings) {
  settings.selectedOpeningMoves.clear();
  settings.botOpeningMove = BotOpeningMove.none;
}

void _pendingApplyOpeningSelection(_PendingBotSettings settings) {
  if (settings.selectedOpeningMoves.isEmpty) {
    settings.botOpeningMove = BotOpeningMove.none;
  } else if (settings.selectedOpeningMoves.length == 1) {
    settings.botOpeningMove = settings.selectedOpeningMoves.first;
  } else {
    settings.botOpeningMove = BotOpeningMove.random;
  }
}

void _pendingSetBotPersonality(
  _PendingBotSettings settings,
  BotPersonality personality,
) {
  settings.botPersonalitySource = BotPersonalitySource.chessiverse;
  settings.botPersonality = personality;
  settings.selectedChessiversePersonalities.clear();
  settings.selectedFritz19Personalities.clear();
}

void _pendingToggleChessiversePersonalitySelection(
  _PendingBotSettings settings,
  BotPersonality personality,
) {
  if (!personality.isConcretePersonality) {
    _pendingSetBotPersonality(settings, personality);
    return;
  }

  if (settings.botPersonalitySource != BotPersonalitySource.chessiverse) {
    settings.selectedChessiversePersonalities.clear();
  } else if (settings.selectedChessiversePersonalities.isEmpty &&
      settings.botPersonality.isConcretePersonality) {
    settings.selectedChessiversePersonalities.add(settings.botPersonality);
  }

  settings.selectedFritz19Personalities.clear();

  if (settings.selectedChessiversePersonalities.contains(personality)) {
    settings.selectedChessiversePersonalities.remove(personality);
  } else {
    settings.selectedChessiversePersonalities.add(personality);
  }

  _pendingApplyChessiversePersonalitySelection(settings);
}

void _pendingSetFritz19Personality(
  _PendingBotSettings settings,
  Fritz19Personality personality,
) {
  settings.botPersonalitySource = BotPersonalitySource.fritz19;
  settings.fritz19Personality = personality;
  settings.selectedChessiversePersonalities.clear();
  settings.selectedFritz19Personalities.clear();
}

void _pendingToggleFritz19PersonalitySelection(
  _PendingBotSettings settings,
  Fritz19Personality personality,
) {
  if (!personality.isConcretePersonality) {
    _pendingSetFritz19Personality(settings, personality);
    return;
  }

  if (settings.botPersonalitySource != BotPersonalitySource.fritz19) {
    settings.selectedFritz19Personalities.clear();
  } else if (settings.selectedFritz19Personalities.isEmpty &&
      settings.fritz19Personality.isConcretePersonality) {
    settings.selectedFritz19Personalities.add(settings.fritz19Personality);
  }

  settings.selectedChessiversePersonalities.clear();

  if (settings.selectedFritz19Personalities.contains(personality)) {
    settings.selectedFritz19Personalities.remove(personality);
  } else {
    settings.selectedFritz19Personalities.add(personality);
  }

  _pendingApplyFritz19PersonalitySelection(settings);
}

void _pendingClearPersonalitySelection(_PendingBotSettings settings) {
  settings.botPersonalitySource = BotPersonalitySource.chessiverse;
  settings.botPersonality = BotPersonality.none;
  settings.fritz19Personality = Fritz19Personality.allrounder;
  settings.selectedChessiversePersonalities.clear();
  settings.selectedFritz19Personalities.clear();
}

void _pendingSetAllPersonalitiesRandom(_PendingBotSettings settings) {
  settings.botPersonalitySource = BotPersonalitySource.random;
  settings.selectedChessiversePersonalities.clear();
  settings.selectedFritz19Personalities.clear();
}

void _pendingApplyChessiversePersonalitySelection(
  _PendingBotSettings settings,
) {
  settings.botPersonalitySource = BotPersonalitySource.chessiverse;
  settings.selectedFritz19Personalities.clear();

  if (settings.selectedChessiversePersonalities.isEmpty) {
    settings.botPersonality = BotPersonality.none;
  } else if (settings.selectedChessiversePersonalities.length == 1) {
    settings.botPersonality = settings.selectedChessiversePersonalities.first;
  } else {
    settings.botPersonality = BotPersonality.random;
  }
}

void _pendingApplyFritz19PersonalitySelection(
  _PendingBotSettings settings,
) {
  settings.botPersonalitySource = BotPersonalitySource.fritz19;
  settings.selectedChessiversePersonalities.clear();

  if (settings.selectedFritz19Personalities.isEmpty) {
    settings.botPersonalitySource = BotPersonalitySource.chessiverse;
    settings.botPersonality = BotPersonality.none;
    settings.fritz19Personality = Fritz19Personality.allrounder;
  } else if (settings.selectedFritz19Personalities.length == 1) {
    settings.fritz19Personality = settings.selectedFritz19Personalities.first;
  } else {
    settings.fritz19Personality = Fritz19Personality.random;
  }
}

void _controllerSetSkillLevel(ChessBoardController controller, int level) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => settings.skillLevel = level,
    );
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

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => settings.strengthMode = mode,
    );
    return;
  }

  controller._strengthMode = mode;
  _safeNotify(controller);
}

void _controllerSetUciElo(ChessBoardController controller, int elo) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  final normalizedElo = elo.clamp(1320, 3190).toInt();

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => settings.uciElo = normalizedElo,
    );
    return;
  }

  controller._uciElo = normalizedElo;
  _safeNotify(controller);
}

void _controllerSetCpLossElo(ChessBoardController controller, int elo) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  final rounded = (elo / 100).round() * 100;
  final normalizedElo = rounded.clamp(0, 4000).toInt();

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => settings.cpLossElo = normalizedElo,
    );
    return;
  }

  controller._cpLossElo = normalizedElo;
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

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) =>
          settings.cpLossUciSwitchFullMoveNumber = fullMoveNumber,
    );
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

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingSetBotPersonality(settings, personality),
    );
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.chessiverse;
  controller._botPersonality = personality;
  controller._selectedChessiversePersonalities.clear();
  controller._selectedFritz19Personalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);

  if (personality == BotPersonality.random) {
    controller._resolvedRandomPersonality = _randomBotPersonality();
  }

  _safeNotify(controller);
}

void _controllerToggleChessiversePersonalitySelection(
  ChessBoardController controller,
  BotPersonality personality,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingToggleChessiversePersonalitySelection(
        settings,
        personality,
      ),
    );
    return;
  }

  if (!personality.isConcretePersonality) {
    _controllerSetBotPersonality(controller, personality);
    return;
  }

  if (controller._botPersonalitySource != BotPersonalitySource.chessiverse) {
    controller._selectedChessiversePersonalities.clear();
  } else if (controller._selectedChessiversePersonalities.isEmpty &&
      controller._botPersonality.isConcretePersonality) {
    controller._selectedChessiversePersonalities.add(controller._botPersonality);
  }

  controller._selectedFritz19Personalities.clear();

  if (controller._selectedChessiversePersonalities.contains(personality)) {
    controller._selectedChessiversePersonalities.remove(personality);
  } else {
    controller._selectedChessiversePersonalities.add(personality);
  }

  _controllerApplyChessiversePersonalitySelection(controller);
  _safeNotify(controller);
}

void _controllerSetFritz19Personality(
  ChessBoardController controller,
  Fritz19Personality personality,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingSetFritz19Personality(settings, personality),
    );
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.fritz19;
  controller._fritz19Personality = personality;
  controller._selectedChessiversePersonalities.clear();
  controller._selectedFritz19Personalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);

  if (personality == Fritz19Personality.random) {
    controller._resolvedRandomFritz19Personality =
        _randomFritz19Personality();
  }

  _safeNotify(controller);
}

void _controllerToggleFritz19PersonalitySelection(
  ChessBoardController controller,
  Fritz19Personality personality,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => _pendingToggleFritz19PersonalitySelection(
        settings,
        personality,
      ),
    );
    return;
  }

  if (!personality.isConcretePersonality) {
    _controllerSetFritz19Personality(controller, personality);
    return;
  }

  if (controller._botPersonalitySource != BotPersonalitySource.fritz19) {
    controller._selectedFritz19Personalities.clear();
  } else if (controller._selectedFritz19Personalities.isEmpty &&
      controller._fritz19Personality.isConcretePersonality) {
    controller._selectedFritz19Personalities.add(controller._fritz19Personality);
  }

  controller._selectedChessiversePersonalities.clear();

  if (controller._selectedFritz19Personalities.contains(personality)) {
    controller._selectedFritz19Personalities.remove(personality);
  } else {
    controller._selectedFritz19Personalities.add(personality);
  }

  _controllerApplyFritz19PersonalitySelection(controller);
  _safeNotify(controller);
}

void _controllerClearPersonalitySelection(
  ChessBoardController controller,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      _pendingClearPersonalitySelection,
    );
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.chessiverse;
  controller._botPersonality = BotPersonality.none;
  controller._fritz19Personality = Fritz19Personality.allrounder;
  controller._selectedChessiversePersonalities.clear();
  controller._selectedFritz19Personalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);

  _safeNotify(controller);
}

void _controllerSetAllPersonalitiesRandom(
  ChessBoardController controller,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      _pendingSetAllPersonalitiesRandom,
    );
    return;
  }

  controller._botPersonalitySource = BotPersonalitySource.random;
  controller._selectedChessiversePersonalities.clear();
  controller._selectedFritz19Personalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);
  _controllerResolveRandomPersonalities(controller);

  _safeNotify(controller);
}

void _controllerApplyChessiversePersonalitySelection(
  ChessBoardController controller,
) {
  controller._botPersonalitySource = BotPersonalitySource.chessiverse;
  controller._selectedFritz19Personalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);

  if (controller._selectedChessiversePersonalities.isEmpty) {
    controller._botPersonality = BotPersonality.none;
  } else if (controller._selectedChessiversePersonalities.length == 1) {
    controller._botPersonality =
        controller._selectedChessiversePersonalities.first;
  } else {
    controller._botPersonality = BotPersonality.random;
    controller._resolvedRandomPersonality =
        _randomBotPersonalityFromSelection(
      controller._selectedChessiversePersonalities,
    );
  }
}

void _controllerApplyFritz19PersonalitySelection(
  ChessBoardController controller,
) {
  controller._botPersonalitySource = BotPersonalitySource.fritz19;
  controller._selectedChessiversePersonalities.clear();
  _controllerResetResolvedRandomPersonalities(controller);

  if (controller._selectedFritz19Personalities.isEmpty) {
    controller._botPersonalitySource = BotPersonalitySource.chessiverse;
    controller._botPersonality = BotPersonality.none;
    controller._fritz19Personality = Fritz19Personality.allrounder;
  } else if (controller._selectedFritz19Personalities.length == 1) {
    controller._fritz19Personality =
        controller._selectedFritz19Personalities.first;
  } else {
    controller._fritz19Personality = Fritz19Personality.random;
    controller._resolvedRandomFritz19Personality =
        _randomFritz19PersonalityFromSelection(
      controller._selectedFritz19Personalities,
    );
  }
}

void _controllerSetPersonaCandidateCount(
  ChessBoardController controller,
  int candidateCount,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  final normalizedCandidateCount = candidateCount.clamp(4, 128).toInt();

  if (_controllerShouldQueueBotSettings(controller)) {
    _queueBotSettingsChange(
      controller,
      (settings) => settings.personaCandidateCount =
          normalizedCandidateCount,
    );
    return;
  }

  controller._personaCandidateCount = normalizedCandidateCount;
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

  if (controller._botPersonalitySource == BotPersonalitySource.random) {
    controller._resolvedRandomPersonality ??= _randomBotPersonality();
    return controller._resolvedRandomPersonality!;
  }

  if (controller._botPersonality == BotPersonality.random) {
    controller._resolvedRandomPersonality ??=
        controller._selectedChessiversePersonalities.length >= 2
            ? _randomBotPersonalityFromSelection(
                controller._selectedChessiversePersonalities,
              )
            : _randomBotPersonality();

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

  if (controller._botPersonalitySource == BotPersonalitySource.random) {
    controller._resolvedRandomFritz19Personality ??=
        _randomFritz19Personality();
    return controller._resolvedRandomFritz19Personality!;
  }

  if (controller._fritz19Personality == Fritz19Personality.random) {
    controller._resolvedRandomFritz19Personality ??=
        controller._selectedFritz19Personalities.length >= 2
            ? _randomFritz19PersonalityFromSelection(
                controller._selectedFritz19Personalities,
              )
            : _randomFritz19Personality();

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

    return 'Fritz19: ${controller._fritz19Personality.label}';
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
  return _randomBotPersonalityFromSelection(
    BotPersonality.concretePersonalities,
  );
}

BotPersonality _randomBotPersonalityFromSelection(
  List<BotPersonality> personalities,
) {
  final selectablePersonalities = personalities
      .where((personality) => personality.isConcretePersonality)
      .toList();

  if (selectablePersonalities.isEmpty) {
    return BotPersonality.abstract;
  }

  selectablePersonalities.shuffle();

  return selectablePersonalities.first;
}

Fritz19Personality _randomFritz19Personality() {
  return _randomFritz19PersonalityFromSelection(
    Fritz19Personality.concretePersonalities,
  );
}

Fritz19Personality _randomFritz19PersonalityFromSelection(
  List<Fritz19Personality> personalities,
) {
  final selectablePersonalities = personalities
      .where((personality) => personality.isConcretePersonality)
      .toList();

  if (selectablePersonalities.isEmpty) {
    return Fritz19Personality.allrounder;
  }

  selectablePersonalities.shuffle();

  return selectablePersonalities.first;
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



