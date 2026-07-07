part of chess_board_controller;

void _controllerRestorePersistedStateIfNeeded(
  ChessBoardController controller,
) {
  if (controller._hasLoadedPersistedState) {
    return;
  }

  controller._hasLoadedPersistedState = true;

  final state = BetterBotsDatabase.instance.loadAppState();

  if (state == null) {
    return;
  }

  controller
    .._playerSide = _playerSideFromName(state.playerSideName)
    .._skillLevel = state.skillLevel.clamp(0, 20).toInt()
    .._strengthMode = _strengthModeFromName(state.strengthModeName)
    .._uciElo = state.uciElo.clamp(1320, 3190).toInt()
    .._cpLossElo = state.cpLossElo.clamp(0, 4000).toInt()
    .._cpLossUciSwitchFullMoveNumber =
        _normalizedCpLossSwitchFullMoveNumber(
          state.cpLossUciSwitchFullMoveNumber,
        )
    .._botOpeningMove = _openingMoveFromName(state.botOpeningMoveName)
    .._resolvedRandomOpeningMove =
        _openingMoveFromNameOrNull(state.effectiveBotOpeningMoveName)
    .._selectedOpeningMoves
        .addAll(_openingMoveListFromNames(state.selectedOpeningMoveNames))
    .._botPersonalitySource =
        _botPersonalitySourceFromName(state.personalitySourceName)
    .._resolvedRandomPersonalitySource =
        _botPersonalitySourceFromNameOrNull(
          state.effectivePersonalitySourceName,
        )
    .._botPersonality = _botPersonalityFromName(state.botPersonalityName)
    .._resolvedRandomPersonality =
        _botPersonalityFromNameOrNull(state.effectiveBotPersonalityName)
    .._fritz19Personality =
        _fritz19PersonalityFromName(state.fritz19PersonalityName)
    .._resolvedRandomFritz19Personality =
        _fritz19PersonalityFromNameOrNull(
          state.effectiveFritz19PersonalityName,
        )
    .._selectedChessiversePersonalities.addAll(
      _botPersonalityListFromNames(state.selectedChessiversePersonalityNames),
    )
    .._selectedFritz19Personalities.addAll(
      _fritz19PersonalityListFromNames(state.selectedFritz19PersonalityNames),
    )
    .._personaCandidateCount =
        state.personaCandidateCount.clamp(4, 128).toInt()
    .._openingLogicAllowed = state.openingLogicAllowed != 0
    .._analysisUsedDuringCurrentGame =
        state.analysisUsedDuringCurrentGame != 0
    .._resultCountedForCurrentGame =
        state.resultCountedForCurrentGame != 0
    .._isBotThinking = false
    .._selectedSquare = null
    .._premoves.clear();

  if (controller._selectedOpeningMoves.length >= 2) {
    controller._botOpeningMove = BotOpeningMove.random;
  } else if (controller._botOpeningMove != BotOpeningMove.random) {
    controller._resolvedRandomOpeningMove = null;
  }

  if (controller._botPersonalitySource != BotPersonalitySource.random) {
    controller._resolvedRandomPersonalitySource = null;
  }

  if (controller._botPersonality != BotPersonality.random &&
      controller._botPersonalitySource != BotPersonalitySource.random) {
    controller._resolvedRandomPersonality = null;
  }

  if (controller._fritz19Personality != Fritz19Personality.random &&
      controller._botPersonalitySource != BotPersonalitySource.random) {
    controller._resolvedRandomFritz19Personality = null;
  }

  _restoreNormalGameFromState(controller, state);
  _controllerRefreshTrainingCounterSnapshot(controller);
}

void _controllerPersistCurrentState(ChessBoardController controller) {
  if (!BetterBotsDatabase.instance.isReady) {
    return;
  }

  final effectiveOpeningMove = controller.effectiveBotOpeningMove;
  final effectivePersonalitySource = controller.effectiveBotPersonalitySource;
  final effectiveBotPersonality = controller.effectiveBotPersonality;
  final effectiveFritz19Personality = controller.effectiveFritz19Personality;

  BetterBotsDatabase.instance.saveAppState(
    AppStateEntity(
      id: 1,
      playerSideName: controller._playerSide.name,
      skillLevel: controller._skillLevel,
      strengthModeName: controller._strengthMode.name,
      uciElo: controller._uciElo,
      cpLossElo: controller._cpLossElo,
      cpLossUciSwitchFullMoveNumber:
          controller._cpLossUciSwitchFullMoveNumber,
      botOpeningMoveName: controller._botOpeningMove.name,
      effectiveBotOpeningMoveName: effectiveOpeningMove.name,
      selectedOpeningMoveNames: _encodeOpeningMoves(
        controller._selectedOpeningMoves,
      ),
      personalitySourceName: controller._botPersonalitySource.name,
      effectivePersonalitySourceName: effectivePersonalitySource.name,
      botPersonalityName: controller._botPersonality.name,
      effectiveBotPersonalityName: effectiveBotPersonality.name,
      fritz19PersonalityName: controller._fritz19Personality.name,
      effectiveFritz19PersonalityName: effectiveFritz19Personality.name,
      selectedChessiversePersonalityNames: _encodeBotPersonalities(
        controller._selectedChessiversePersonalities,
      ),
      selectedFritz19PersonalityNames: _encodeFritz19Personalities(
        controller._selectedFritz19Personalities,
      ),
      personaCandidateCount: controller._personaCandidateCount,
      openingLogicAllowed: controller._openingLogicAllowed ? 1 : 0,
      startFen: controller._normalGameStartFen,
      moveListText: _encodeBoardMoves(controller._normalGameMoves),
      currentFen: controller._game.fen,
      lastFrom: controller._lastFrom ?? '',
      lastTo: controller._lastTo ?? '',
      analysisUsedDuringCurrentGame:
          controller._analysisUsedDuringCurrentGame ? 1 : 0,
      resultCountedForCurrentGame:
          controller._resultCountedForCurrentGame ? 1 : 0,
    ),
  );
}

void _controllerRefreshTrainingCounterSnapshot(
  ChessBoardController controller,
) {
  controller._trainingCounterSnapshot =
      BetterBotsDatabase.instance.counterSnapshotFor(
    strengthMode: controller._strengthMode,
    skillLevel: controller._skillLevel,
    uciElo: controller._uciElo,
    cpLossElo: controller._cpLossElo,
    cpLossUciSwitchFullMoveNumber:
        controller._cpLossUciSwitchFullMoveNumber,
    effectiveOpeningMove: controller.effectiveBotOpeningMove,
    personalitySourceName: _effectiveCounterPersonalitySourceName(controller),
    effectivePersonalityName: _effectiveCounterPersonalityName(controller),
    personaCandidateCount: controller._personaCandidateCount,
  );
}

void _controllerMaybeCountCompletedGame(ChessBoardController controller) {
  if (controller.isAnalysisMode ||
      controller._resultCountedForCurrentGame ||
      controller._analysisUsedDuringCurrentGame) {
    return;
  }

  final increment = _gameResultCounterIncrement(controller);

  if (increment == null) {
    return;
  }

  controller._trainingCounterSnapshot =
      BetterBotsDatabase.instance.incrementCounter(
    increment: increment,
    playerSide: controller._playerSide,
    strengthMode: controller._strengthMode,
    skillLevel: controller._skillLevel,
    uciElo: controller._uciElo,
    cpLossElo: controller._cpLossElo,
    cpLossUciSwitchFullMoveNumber:
        controller._cpLossUciSwitchFullMoveNumber,
    effectiveOpeningMove: controller.effectiveBotOpeningMove,
    personalitySourceName: _effectiveCounterPersonalitySourceName(controller),
    effectivePersonalityName: _effectiveCounterPersonalityName(controller),
    personaCandidateCount: controller._personaCandidateCount,
  );

  controller._resultCountedForCurrentGame = true;
}

void _controllerRestartTrainingCounterGame(ChessBoardController controller) {
  if (controller.isAnalysisMode) {
    return;
  }

  controller._trainingCounterSnapshot =
      BetterBotsDatabase.instance.incrementCounter(
    increment: TrainingCounterIncrement.trained,
    playerSide: controller._playerSide,
    strengthMode: controller._strengthMode,
    skillLevel: controller._skillLevel,
    uciElo: controller._uciElo,
    cpLossElo: controller._cpLossElo,
    cpLossUciSwitchFullMoveNumber:
        controller._cpLossUciSwitchFullMoveNumber,
    effectiveOpeningMove: controller.effectiveBotOpeningMove,
    personalitySourceName: _effectiveCounterPersonalitySourceName(controller),
    effectivePersonalityName: _effectiveCounterPersonalityName(controller),
    personaCandidateCount: controller._personaCandidateCount,
  );

  controller.newGame(controller._playerSide);
}

TrainingCounterIncrement? _gameResultCounterIncrement(
  ChessBoardController controller,
) {
  if (controller._game.in_checkmate) {
    final winner = controller._game.turn == chess.Color.WHITE
        ? chess.Color.BLACK
        : chess.Color.WHITE;
    final player = controller.playerIsWhite
        ? chess.Color.WHITE
        : chess.Color.BLACK;

    return winner == player
        ? TrainingCounterIncrement.won
        : TrainingCounterIncrement.lost;
  }

  if (controller._game.in_stalemate || controller._game.in_draw) {
    return TrainingCounterIncrement.draw;
  }

  return null;
}

void _restoreNormalGameFromState(
  ChessBoardController controller,
  AppStateEntity state,
) {
  final startFen = state.startFen.trim().isEmpty
      ? _defaultStartFen
      : state.startFen.trim();
  final currentFen = state.currentFen.trim();

  controller._normalGameStartFen = startFen;
  controller._normalGameMoves.clear();

  var loaded = false;

  try {
    loaded = controller._game.load(startFen);
  } catch (_) {
    loaded = false;
  }

  if (loaded) {
    final moves = _decodeBoardMoves(state.moveListText);
    var replayFailed = false;

    for (final move in moves) {
      final moved = _applyBoardMove(controller._game, move);

      if (!moved) {
        replayFailed = true;
        break;
      }

      controller._normalGameMoves.add(move);
    }

    if (!replayFailed) {
      final lastMove = controller._normalGameMoves.isEmpty
          ? null
          : controller._normalGameMoves.last;
      controller
        .._lastFrom = state.lastFrom.isEmpty ? lastMove?.from : state.lastFrom
        .._lastTo = state.lastTo.isEmpty ? lastMove?.to : state.lastTo;
      return;
    }
  }

  var fallbackLoaded = false;

  if (currentFen.isNotEmpty) {
    try {
      fallbackLoaded = controller._game.load(currentFen);
    } catch (_) {
      fallbackLoaded = false;
    }
  }

  if (!fallbackLoaded) {
    controller._game.reset();
    controller._normalGameStartFen = _defaultStartFen;
  } else {
    controller._normalGameStartFen = currentFen;
  }

  controller
    .._normalGameMoves.clear()
    .._lastFrom = null
    .._lastTo = null;
}

bool _applyBoardMove(chess.Chess game, BoardMove move) {
  final moveData = <String, String>{
    'from': move.from,
    'to': move.to,
  };

  final promotion = move.promotion;

  if (promotion != null && promotion.isNotEmpty) {
    moveData['promotion'] = promotion;
  }

  return game.move(moveData);
}

String _encodeBoardMoves(List<BoardMove> moves) {
  return moves.map((move) => move.toString()).join(' ');
}

List<BoardMove> _decodeBoardMoves(String text) {
  final tokens = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty);

  final moves = <BoardMove>[];

  for (final token in tokens) {
    if (token.length < 4) {
      continue;
    }

    final from = token.substring(0, 2);
    final to = token.substring(2, 4);
    final promotion = token.length >= 5 ? token.substring(4, 5) : null;

    moves.add(
      BoardMove(
        from: from,
        to: to,
        promotion: promotion == null || promotion.isEmpty
            ? null
            : promotion.toLowerCase(),
      ),
    );
  }

  return moves;
}

String _encodeOpeningMoves(List<BotOpeningMove> openingMoves) {
  return openingMoves.map((openingMove) => openingMove.name).join(',');
}

List<BotOpeningMove> _openingMoveListFromNames(String names) {
  return names
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .map(_openingMoveFromName)
      .where((openingMove) => openingMove.isRealOpening)
      .toList();
}

String _encodeBotPersonalities(List<BotPersonality> personalities) {
  return personalities.map((personality) => personality.name).join(',');
}

List<BotPersonality> _botPersonalityListFromNames(String names) {
  return names
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .map(_botPersonalityFromName)
      .where((personality) => personality.isConcretePersonality)
      .toList();
}

String _encodeFritz19Personalities(
  List<Fritz19Personality> personalities,
) {
  return personalities.map((personality) => personality.name).join(',');
}

List<Fritz19Personality> _fritz19PersonalityListFromNames(String names) {
  return names
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .map(_fritz19PersonalityFromName)
      .where((personality) => personality.isConcretePersonality)
      .toList();
}

String _effectiveCounterPersonalitySourceName(
  ChessBoardController controller,
) {
  return controller.effectiveBotPersonalitySource.name;
}

String _effectiveCounterPersonalityName(ChessBoardController controller) {
  if (controller.effectiveBotPersonalitySource == BotPersonalitySource.fritz19) {
    return controller.effectiveFritz19Personality.name;
  }

  return controller.effectiveBotPersonality.name;
}

PlayerSide _playerSideFromName(String name) {
  for (final side in PlayerSide.values) {
    if (side.name == name) {
      return side;
    }
  }

  return PlayerSide.white;
}

EngineStrengthMode _strengthModeFromName(String name) {
  for (final mode in EngineStrengthMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }

  return EngineStrengthMode.cpLossElo;
}

BotOpeningMove _openingMoveFromName(String name) {
  for (final move in BotOpeningMove.values) {
    if (move.name == name) {
      return move;
    }
  }

  return BotOpeningMove.random;
}

BotOpeningMove? _openingMoveFromNameOrNull(String name) {
  if (name.isEmpty || name == BotOpeningMove.random.name) {
    return null;
  }

  return _openingMoveFromName(name);
}

BotPersonality _botPersonalityFromName(String name) {
  for (final personality in BotPersonality.values) {
    if (personality.name == name) {
      return personality;
    }
  }

  return BotPersonality.random;
}

BotPersonality? _botPersonalityFromNameOrNull(String name) {
  if (name.isEmpty || name == BotPersonality.random.name) {
    return null;
  }

  return _botPersonalityFromName(name);
}

BotPersonalitySource _botPersonalitySourceFromName(String name) {
  return _botPersonalitySourceFromNameOrNull(name) ??
      BotPersonalitySource.chessiverse;
}

BotPersonalitySource? _botPersonalitySourceFromNameOrNull(String name) {
  for (final source in BotPersonalitySource.values) {
    if (source.name == name) {
      return source;
    }
  }

  return null;
}

Fritz19Personality _fritz19PersonalityFromName(String name) {
  return _fritz19PersonalityFromNameOrNull(name) ??
      Fritz19Personality.allrounder;
}

Fritz19Personality? _fritz19PersonalityFromNameOrNull(String name) {
  for (final personality in Fritz19Personality.values) {
    if (personality.name == name) {
      return personality;
    }
  }

  return null;
}

int _normalizedCpLossSwitchFullMoveNumber(int fullMoveNumber) {
  const allowedMoves = <int>[6, 11, 16, 21, 26];

  if (allowedMoves.contains(fullMoveNumber)) {
    return fullMoveNumber;
  }

  return 11;
}
