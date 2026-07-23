part of chess_board_controller;

const String _defaultStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

const int _cpLossUciSwitchMinElo = 1400;
const int _cpLossUciSwitchMaxElo = 3100;

void _controllerStart(ChessBoardController controller) {
  controller._engineSubscription ??= controller._engine.output.listen((line) {
    if (controller._isDisposed) {
      return;
    }

    controller._engineOutput = line;
    controller.notifyListeners();
  });

  controller._botProfileEngineSubscription ??=
      controller._botProfileEngine.output.listen((line) {
    if (controller._isDisposed) {
      return;
    }

    controller._engineOutput = line;
    controller.notifyListeners();
  });

  _controllerRestorePersistedStateIfNeeded(controller);
  _safeNotify(controller);

  if (!controller.isGameOver && !controller.isPlayersTurn) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }
}

Future<void> _controllerMakeBotMoveIfNeeded(
  ChessBoardController controller,
) async {
  if (controller._isSoloMode) {
    return;
  }

  if (controller.isAnalysisMode) {
    return;
  }

  if (_controllerIsNormalReviewMode(controller)) {
    return;
  }

  if (controller.isGameOver) {
    return;
  }

  if (controller.isPlayersTurn) {
    return;
  }

  controller._isBotThinking = true;
  _safeNotify(controller);

  final currentSearchGeneration = ++controller._searchGeneration;
  var botMoved = false;

  try {
    final openingMove = _getForcedOpeningMove(controller);

    if (openingMove != null) {
      if (controller._isDisposed ||
          currentSearchGeneration != controller._searchGeneration) {
        return;
      }

      botMoved = _applyUciMove(controller, openingMove);
    } else {
      final activeBotProfile = controller._activeBotProfile;

      if (activeBotProfile != null) {
        final botMove = await _selectMoveWithActiveBotProfile(
          controller: controller,
          profile: activeBotProfile,
        );

        if (controller._isDisposed ||
            currentSearchGeneration != controller._searchGeneration) {
          return;
        }

        botMoved = _applyUciMove(controller, botMove);
      } else {
        final currentFen = controller._game.fen;
        final effectivePersonality = _controllerEffectiveBotPersonality(
          controller,
        );
        final effectivePersonalitySource =
            _controllerEffectiveBotPersonalitySource(controller);
        final effectiveFritz19Personality =
            _controllerEffectiveFritz19Personality(controller);
        final usesFritz19 =
            effectivePersonalitySource == BotPersonalitySource.fritz19;

        String botMove;

        if (controller._strengthMode == EngineStrengthMode.cpLossElo) {
          final shouldUseUciEloInsteadOfCpLoss =
              _shouldUseUciEloInsteadOfCpLoss(controller);

          if (shouldUseUciEloInsteadOfCpLoss) {
            botMove = await _selectMoveWithUciEloAfterCpLossSwitch(
              controller: controller,
              fen: currentFen,
              personality: effectivePersonality,
            );
          } else {
            botMove = await _selectMoveWithCpLossElo(
              controller: controller,
              fen: currentFen,
              personality: effectivePersonality,
            );
          }
        } else if (!usesFritz19 &&
            effectivePersonality == BotPersonality.none) {
          botMove = await controller._engine.getBestMoveFromFen(
            fen: currentFen,
            skillLevel: controller._skillLevel,
            useUciElo: controller._strengthMode == EngineStrengthMode.uciElo,
            uciElo: controller._uciElo,
            moveTimeMs: 800,
          );
        } else {
          final candidates = await controller._engine.getMoveCandidatesFromFen(
            fen: currentFen,
            skillLevel: controller._skillLevel,
            useUciElo: controller._strengthMode == EngineStrengthMode.uciElo,
            uciElo: controller._uciElo,
            candidateCount: controller._personaCandidateCount,
            moveTimeMs: 800,
          );

          if (usesFritz19) {
            final selection = const Fritz19MoveSelector().selectMove(
              fen: currentFen,
              candidates: candidates,
              personality: effectiveFritz19Personality,
              skillLevel: controller._skillLevel,
              useUciElo: controller._strengthMode == EngineStrengthMode.uciElo,
              uciElo: controller._uciElo,
            );

            botMove = selection.uciMove;
            controller._engineOutput = selection.debugText;
          } else {
            botMove = const PersonaMoveSelector().selectMove(
              fen: currentFen,
              candidates: candidates,
              personality: effectivePersonality,
              skillLevel: controller._skillLevel,
              useUciElo: controller._strengthMode == EngineStrengthMode.uciElo,
              uciElo: controller._uciElo,
            );

            controller._engineOutput =
                'Chessiverse: ${effectivePersonality.label} | '
                'Kandidaten: ${controller._personaCandidateCount} | '
                'Zug: $botMove';
          }
        }

        if (controller._isDisposed ||
            currentSearchGeneration != controller._searchGeneration) {
          return;
        }

        botMoved = _applyUciMove(controller, botMove);
      }
    }
  } catch (e) {
    if (controller._isDisposed ||
        currentSearchGeneration != controller._searchGeneration) {
      return;
    }

    controller._engineOutput = e.toString();
    _safeNotify(controller);
  } finally {
    if (!controller._isDisposed &&
        currentSearchGeneration == controller._searchGeneration) {
      controller._isBotThinking = false;
      _safeNotify(controller);
    }
  }

  if (!controller._isDisposed &&
      currentSearchGeneration == controller._searchGeneration &&
      botMoved) {
    await _tryPlayNextPremoveIfPossible(controller);
  }
}


Future<String> _selectMoveWithActiveBotProfile({
  required ChessBoardController controller,
  required BotProfile profile,
}) async {
  final botEngine = controller._botProfileEngine;
  final moveHistory = controller._normalGameMoves
      .map((move) => move.toString())
      .toList(growable: false);

  String botMove;

  if (botEngine is Maia3WindowsUciEngine) {
    botMove = await botEngine.getBestMoveFromGame(
      startFen: controller._normalGameStartFen,
      moves: moveHistory,
      fen: controller._game.fen,
      elo: profile.rating,
      temperature: profile.defaultTemperature,
      topP: profile.defaultTopP,
    );
  } else if (botEngine is Maia3AndroidMethodChannelEngine) {
    botMove = await botEngine.getBestMoveFromGame(
      startFen: controller._normalGameStartFen,
      moves: moveHistory,
      fen: controller._game.fen,
      elo: profile.rating,
      temperature: profile.defaultTemperature,
      topP: profile.defaultTopP,
    );
  } else {
    throw UnsupportedError(
      'Für ${profile.displayName} ist auf dieser Plattform noch keine '
      'Maia-Engine verfügbar.',
    );
  }

  controller._engineOutput = '${profile.displayName} | Zug: $botMove';

  return botMove;
}

Future<String> _selectMoveWithCpLossElo({
  required ChessBoardController controller,
  required String fen,
  required BotPersonality personality,
}) async {
  final candidates = await controller._engine.getMoveCandidatesFromFen(
    fen: fen,
    skillLevel: 20,
    useUciElo: false,
    uciElo: controller._uciElo,
    candidateCount: controller._personaCandidateCount,
    moveTimeMs: 800,
  );

  const cpLossSelector = CpLossMoveSelector();

  final cpLossPool = cpLossSelector.buildCandidatePool(
    candidates: candidates,
    cpLossElo: controller._cpLossElo,
  );

  final effectivePersonalitySource =
      _controllerEffectiveBotPersonalitySource(controller);
  final effectiveFritz19Personality =
      _controllerEffectiveFritz19Personality(controller);

  if (effectivePersonalitySource == BotPersonalitySource.fritz19) {
    final selection = const Fritz19MoveSelector().selectMoveFromCpLossPool(
      fen: fen,
      pool: cpLossPool,
      personality: effectiveFritz19Personality,
    );

    final chosenCpLoss = cpLossSelector.cpLossForMoveInPool(
      pool: cpLossPool,
      uciMove: selection.uciMove,
    );

    controller._engineOutput =
        '${cpLossPool.debugPrefix} | '
        'Fritz19: ${effectiveFritz19Personality.label} | '
        'Grund: ${selection.reason} | '
        'Style: ${selection.styleScore.toStringAsFixed(1)} | '
        'Gewählt: $chosenCpLoss cp | '
        'Zug: ${selection.uciMove}';

    return selection.uciMove;
  }

  if (personality == BotPersonality.none) {
    final selection = cpLossSelector.selectMoveFromPool(pool: cpLossPool);

    controller._engineOutput = selection.debugText;
    return selection.uciMove;
  }

  final botMove = const PersonaMoveSelector().selectMoveFromCpLossPool(
    fen: fen,
    pool: cpLossPool,
    personality: personality,
    skillLevel: 20,
    useUciElo: false,
    uciElo: controller._uciElo,
  );

  final chosenCpLoss = cpLossSelector.cpLossForMoveInPool(
    pool: cpLossPool,
    uciMove: botMove,
  );

  controller._engineOutput =
      '${cpLossPool.debugPrefix} | '
      'Chessiverse: ${personality.label} | '
      'Gewählt: $chosenCpLoss cp | '
      'Zug: $botMove';

  return botMove;
}

Future<String> _selectMoveWithUciEloAfterCpLossSwitch({
  required ChessBoardController controller,
  required String fen,
  required BotPersonality personality,
}) async {
  final uciEloFromCpLoss = _uciEloFromCpLossElo(controller);
  final fullMoveNumber = _currentFullMoveNumber(controller);

  final effectivePersonalitySource =
      _controllerEffectiveBotPersonalitySource(controller);
  final effectiveFritz19Personality =
      _controllerEffectiveFritz19Personality(controller);

  if (effectivePersonalitySource != BotPersonalitySource.fritz19 &&
      personality == BotPersonality.none) {
    final botMove = await controller._engine.getBestMoveFromFen(
      fen: fen,
      skillLevel: 20,
      useUciElo: true,
      uciElo: uciEloFromCpLoss,
      moveTimeMs: 800,
    );

    controller._engineOutput =
        'CP_Loss_ELO ${controller._cpLossElo} ab Zug '
        '${controller._cpLossUciSwitchFullMoveNumber} → '
        'UCI_ELO $uciEloFromCpLoss | '
        'Aktueller Zug: $fullMoveNumber | '
        'Zug: $botMove';

    return botMove;
  }

  final candidates = await controller._engine.getMoveCandidatesFromFen(
    fen: fen,
    skillLevel: 20,
    useUciElo: true,
    uciElo: uciEloFromCpLoss,
    candidateCount: controller._personaCandidateCount,
    moveTimeMs: 800,
  );

  if (effectivePersonalitySource == BotPersonalitySource.fritz19) {
    final selection = const Fritz19MoveSelector().selectMove(
      fen: fen,
      candidates: candidates,
      personality: effectiveFritz19Personality,
      skillLevel: 20,
      useUciElo: true,
      uciElo: uciEloFromCpLoss,
    );

    controller._engineOutput =
        'CP_Loss_ELO ${controller._cpLossElo} ab Zug '
        '${controller._cpLossUciSwitchFullMoveNumber} → '
        'UCI_ELO $uciEloFromCpLoss | '
        'Aktueller Zug: $fullMoveNumber | '
        '${selection.debugText}';

    return selection.uciMove;
  }

  final botMove = const PersonaMoveSelector().selectMove(
    fen: fen,
    candidates: candidates,
    personality: personality,
    skillLevel: 20,
    useUciElo: true,
    uciElo: uciEloFromCpLoss,
  );

  controller._engineOutput =
      'CP_Loss_ELO ${controller._cpLossElo} ab Zug '
      '${controller._cpLossUciSwitchFullMoveNumber} → '
      'UCI_ELO $uciEloFromCpLoss | '
      'Aktueller Zug: $fullMoveNumber | '
      'Chessiverse: ${personality.label} | '
      'Kandidaten: ${controller._personaCandidateCount} | '
      'Zug: $botMove';

  return botMove;
}

bool _shouldUseUciEloInsteadOfCpLoss(ChessBoardController controller) {
  if (controller._strengthMode != EngineStrengthMode.cpLossElo) {
    return false;
  }

  final cpLossElo = controller._cpLossElo;

  if (cpLossElo < _cpLossUciSwitchMinElo ||
      cpLossElo > _cpLossUciSwitchMaxElo) {
    return false;
  }

  return _currentFullMoveNumber(controller) >=
      controller._cpLossUciSwitchFullMoveNumber;
}

int _uciEloFromCpLossElo(ChessBoardController controller) {
  return controller._cpLossElo
      .clamp(_cpLossUciSwitchMinElo, _cpLossUciSwitchMaxElo)
      .toInt();
}

int _currentFullMoveNumber(ChessBoardController controller) {
  final fen = controller._game.fen;
  final parts = fen.trim().split(RegExp(r'\s+'));

  if (parts.length >= 6) {
    final fullMoveNumber = int.tryParse(parts[5]);

    if (fullMoveNumber != null && fullMoveNumber > 0) {
      return fullMoveNumber;
    }
  }

  return 1;
}

String? _getForcedOpeningMove(ChessBoardController controller) {
  if (!controller._openingLogicAllowed) {
    return null;
  }

  if (controller._botOpeningMove == BotOpeningMove.none) {
    controller._openingLogicAllowed = false;
    return null;
  }

  final selectedOpening = _resolveSelectedOpening(controller);
  final history = controller._game.history;

  if (controller.playerSide == PlayerSide.black) {
    if (history.isNotEmpty) {
      controller._openingLogicAllowed = false;
      return null;
    }

    if (controller._game.fen != _defaultStartFen) {
      controller._openingLogicAllowed = false;
      return null;
    }

    controller._openingLogicAllowed = false;
    return selectedOpening.whiteUci;
  }

  if (controller.playerSide == PlayerSide.white) {
    if (history.length != 1) {
      return null;
    }

    controller._openingLogicAllowed = false;
    return selectedOpening.blackUci;
  }

  return null;
}

BotOpeningMove _resolveSelectedOpening(ChessBoardController controller) {
  if (controller._botOpeningMove != BotOpeningMove.random) {
    return controller._botOpeningMove;
  }

  controller._resolvedRandomOpeningMove ??=
      controller._selectedOpeningMoves.length >= 2
          ? _randomOpeningMoveFromSelection(controller._selectedOpeningMoves)
          : _randomOpeningMove();

  return controller._resolvedRandomOpeningMove!;
}

BotOpeningMove _randomOpeningMove() {
  return _randomOpeningMoveFromSelection(BotOpeningMove.realOpenings);
}

BotOpeningMove _randomOpeningMoveFromSelection(
  List<BotOpeningMove> openingMoves,
) {
  final openings = openingMoves
      .where((openingMove) => openingMove.isRealOpening)
      .toList();

  if (openings.isEmpty) {
    return BotOpeningMove.realOpenings.first;
  }

  openings.shuffle();

  return openings.first;
}

bool _applyUciMove(ChessBoardController controller, String uciMove) {
  if (uciMove.length < 4 || uciMove == '(none)') {
    return false;
  }

  final from = uciMove.substring(0, 2);
  final to = uciMove.substring(2, 4);
  final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : '';

  final moveData = <String, String>{'from': from, 'to': to};

  if (promotion.isNotEmpty) {
    moveData['promotion'] = promotion;
  }

  final moved = controller._game.move(moveData);

  if (!moved) {
    controller._engineOutput =
        'Bot-Zug konnte nicht ausgeführt werden: $uciMove';
    _safeNotify(controller);
    return false;
  }

  _recordNormalGameMove(
    controller,
    from: from,
    to: to,
    promotion: promotion.isEmpty ? null : promotion,
  );

  controller._lastFrom = from;
  controller._lastTo = to;
  controller._selectedSquare = null;

  _safeNotify(controller);

  return true;
}
