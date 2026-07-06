part of chess_board_controller;

Future<void> _controllerOnSquareTap(
  ChessBoardController controller,
  String square,
) async {
  if (controller.isAnalysisMode) {
    await _controllerOnAnalysisSquareTap(controller, square);
    return;
  }

  if (controller.isGameOver) {
    return;
  }

  if (!controller.isPlayersTurn) {
    await _onPremoveSquareTap(controller, square);
    return;
  }

  if (controller._isBotThinking) {
    return;
  }

  final piece = controller._game.get(square);

  if (controller._selectedSquare == null) {
    if (piece == null) {
      return;
    }

    if (!_isOwnPiece(controller, piece)) {
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
  final moved = await _controllerTryHumanMove(
    controller,
    from: from,
    to: square,
  );

  if (moved) {
    return;
  }

  if (piece != null && _isOwnPiece(controller, piece)) {
    _controllerSelectSquare(controller, square);
    return;
  }

  _controllerClearSelectedSquare(controller);
}

Future<bool> _controllerTryHumanMove(
  ChessBoardController controller, {
  required String from,
  required String to,
  String? promotion,
}) async {
  if (controller.isAnalysisMode) {
    return _controllerTryAnalysisMove(
      controller,
      from: from,
      to: to,
      promotion: promotion,
    );
  }

  if (controller.isGameOver) {
    return false;
  }

  if (!controller.isPlayersTurn || controller._isBotThinking) {
    return _addPremove(controller, from: from, to: to, promotion: promotion);
  }

  final selectedPromotion = await _promotionForMoveIfNeeded(
    controller,
    from: from,
    to: to,
    promotion: promotion,
    useVirtualBoard: false,
  );

  if (selectedPromotion == null) {
    _controllerClearSelectedSquare(controller);
    return false;
  }

  final moveData = <String, String>{'from': from, 'to': to};

  if (selectedPromotion.isNotEmpty) {
    moveData['promotion'] = selectedPromotion;
  }

  final moved = controller._game.move(moveData);

  if (!moved) {
    return false;
  }

  _recordNormalGameMove(
    controller,
    from: from,
    to: to,
    promotion: selectedPromotion.isEmpty ? null : selectedPromotion,
  );

  controller._lastFrom = from;
  controller._lastTo = to;
  controller._selectedSquare = null;
  controller._premoves.clear();

  _safeNotify(controller);

  await _controllerMakeBotMoveIfNeeded(controller);

  return true;
}

Future<bool> _controllerLoadFenPosition(
  ChessBoardController controller,
  String fenInput,
) async {
  if (controller.isAnalysisMode) {
    return false;
  }

  final fen = fenInput.trim().replaceAll(RegExp(r'\s+'), ' ');

  if (fen.isEmpty) {
    controller._engineOutput = 'FEN ist leer.';
    _safeNotify(controller);
    return false;
  }

  final testGame = chess.Chess();
  bool loaded;

  try {
    loaded = testGame.load(fen);
  } catch (e) {
    controller._engineOutput = 'Ungültige FEN: $e';
    _safeNotify(controller);
    return false;
  }

  if (!loaded) {
    controller._engineOutput = 'Ungültige FEN.';
    _safeNotify(controller);
    return false;
  }

  controller._searchGeneration++;

  final realLoaded = controller._game.load(fen);

  if (!realLoaded) {
    controller._engineOutput = 'FEN konnte nicht geladen werden.';
    _safeNotify(controller);
    return false;
  }

  _resetNormalGameHistoryFromCurrentFen(controller, fen);

  controller._selectedSquare = null;
  controller._lastFrom = null;
  controller._lastTo = null;
  controller._premoves.clear();
  controller._isBotThinking = false;
  controller._engineOutput = 'FEN geladen.';

  _safeNotify(controller);

  if (!controller.isGameOver && !controller.isPlayersTurn) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }

  return true;
}
