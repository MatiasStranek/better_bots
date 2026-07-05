part of chess_board_controller;

void _controllerStart(ChessBoardController controller) {
  controller._engineSubscription ??= controller._engine.output.listen((line) {
    if (controller._isDisposed) {
      return;
    }

    controller._engineOutput = line;
    controller.notifyListeners();
  });
}

Future<void> _controllerMakeBotMoveIfNeeded(
  ChessBoardController controller,
) async {
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
    final bestMove = await controller._engine.getBestMoveFromFen(
      fen: controller._game.fen,
      skillLevel: controller._skillLevel,
      moveTimeMs: 800,
    );

    if (controller._isDisposed ||
        currentSearchGeneration != controller._searchGeneration) {
      return;
    }

    botMoved = _applyUciMove(controller, bestMove);
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
        'Bot-Zug konnte nicht ausgeführt werden: '
        '$uciMove';
    _safeNotify(controller);
    return false;
  }

  controller._lastFrom = from;
  controller._lastTo = to;
  controller._selectedSquare = null;

  _safeNotify(controller);

  return true;
}
