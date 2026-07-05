part of chess_board_controller;

BoardHighlights _controllerHighlights(ChessBoardController controller) {
  return BoardHighlights(
    selectedSquare: controller._selectedSquare,
    lastFrom: controller._lastFrom,
    lastTo: controller._lastTo,
    premoveSquares: controller._premoves.highlightedSquares,
    legalTargets: _controllerLegalTargetsForSelectedSquare(controller),
  );
}

String _controllerStatusText(ChessBoardController controller) {
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

void _controllerNewGame(ChessBoardController controller, PlayerSide side) {
  controller._searchGeneration++;

  controller._playerSide = side;
  controller._game.reset();
  controller._selectedSquare = null;
  controller._lastFrom = null;
  controller._lastTo = null;
  controller._premoves.clear();

  controller._isBotThinking = false;
  controller._engineOutput = '-';

  controller._openingLogicAllowed = true;
  controller._resolvedRandomOpeningMove = null;

  controller._resolvedRandomPersonality = null;
  if (controller._botPersonality == BotPersonality.random) {
    controller._resolvedRandomPersonality = _randomBotPersonality();
  }

  _safeNotify(controller);

  if (controller._playerSide == PlayerSide.black) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }
}

void _controllerSetSkillLevel(ChessBoardController controller, int level) {
  if (controller._isBotThinking) {
    return;
  }

  controller._skillLevel = level;
  _safeNotify(controller);
}

void _controllerSetStrengthMode(
  ChessBoardController controller,
  EngineStrengthMode mode,
) {
  if (controller._isBotThinking) {
    return;
  }

  controller._strengthMode = mode;
  _safeNotify(controller);
}

void _controllerSetUciElo(ChessBoardController controller, int elo) {
  if (controller._isBotThinking) {
    return;
  }

  controller._uciElo = elo.clamp(1320, 3190);
  _safeNotify(controller);
}

void _controllerSetBotPersonality(
  ChessBoardController controller,
  BotPersonality personality,
) {
  if (controller._isBotThinking) {
    return;
  }

  controller._botPersonality = personality;
  controller._resolvedRandomPersonality = null;

  if (personality == BotPersonality.random) {
    controller._resolvedRandomPersonality = _randomBotPersonality();
  }

  _safeNotify(controller);
}

void _controllerSetPersonaCandidateCount(
  ChessBoardController controller,
  int candidateCount,
) {
  if (controller._isBotThinking) {
    return;
  }

  controller._personaCandidateCount = candidateCount.clamp(4, 128);
  _safeNotify(controller);
}

BotPersonality _controllerEffectiveBotPersonality(
  ChessBoardController controller,
) {
  if (controller._botPersonality == BotPersonality.random) {
    controller._resolvedRandomPersonality ??= _randomBotPersonality();
    return controller._resolvedRandomPersonality!;
  }

  return controller._botPersonality;
}

BotPersonality _randomBotPersonality() {
  final personalities = List<BotPersonality>.from(
    BotPersonality.concretePersonalities,
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
  return piece.color == controller._game.turn;
}

bool _isPlayerPiece(ChessBoardController controller, chess.Piece piece) {
  final playerColor = controller.playerIsWhite
      ? chess.Color.WHITE
      : chess.Color.BLACK;

  return piece.color == playerColor;
}

void _safeNotify(ChessBoardController controller) {
  if (controller._isDisposed) {
    return;
  }

  controller.notifyListeners();
}
