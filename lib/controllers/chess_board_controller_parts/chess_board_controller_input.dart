part of chess_board_controller;

Future<void> _controllerOnSquareTap(
  ChessBoardController controller,
  String square,
) async {
  if (controller.isAnalysisMode) {
    await _controllerOnAnalysisSquareTap(controller, square);
    return;
  }

  if (_controllerIsNormalReviewMode(controller)) {
    controller._selectedSquare = null;
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

  if (_controllerIsNormalReviewMode(controller)) {
    controller._selectedSquare = null;
    return false;
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
  String fenInput, {
  bool markAnalysisUsed = false,
}) async {
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

  controller
    .._openingLogicAllowed = false
    .._resolvedRandomOpeningMove = null
    .._resolvedRandomPersonality = null;

  _resetNormalGameHistoryFromCurrentFen(controller, fen);
  _controllerClearNormalReview(controller);

  controller._selectedSquare = null;
  controller._lastFrom = null;
  controller._lastTo = null;
  controller._premoves.clear();
  controller._isBotThinking = false;
  controller._resultCountedForCurrentGame = false;

  if (markAnalysisUsed) {
    controller._analysisUsedDuringCurrentGame = true;
  }

  controller._engineOutput = 'FEN geladen.';

  _safeNotify(controller);

  if (!controller.isGameOver && !controller.isPlayersTurn) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }

  return true;
}

Future<bool> _controllerLoadPgnGame(
  ChessBoardController controller,
  String pgnInput, {
  bool markAnalysisUsed = false,
}) async {
  if (controller.isAnalysisMode) {
    return false;
  }

  final pgn = pgnInput.trim();

  if (pgn.isEmpty) {
    controller._engineOutput = 'PGN ist leer.';
    _safeNotify(controller);
    return false;
  }

  final parsedGame = chess.Chess();
  var parsed = false;

  try {
    parsed = parsedGame.load_pgn(pgn);
  } catch (error) {
    controller._engineOutput = 'Ungültige PGN: $error';
    _safeNotify(controller);
    return false;
  }

  if (!parsed) {
    controller._engineOutput = 'Ungültige PGN.';
    _safeNotify(controller);
    return false;
  }

  final historyGame = parsedGame.copy();
  final reversedMoves = <BoardMove>[];

  while (true) {
    final dynamic undone = historyGame.undo();

    if (undone == null) {
      break;
    }

    final move = _boardMoveFromPgnHistoryEntry(undone);

    if (move == null) {
      controller._engineOutput = 'PGN-Zugliste konnte nicht gelesen werden.';
      _safeNotify(controller);
      return false;
    }

    reversedMoves.add(move);
  }

  final moves = reversedMoves.reversed.toList(growable: false);
  final startFen = historyGame.fen.trim();

  controller._searchGeneration++;

  var loaded = false;

  try {
    loaded = controller._game.load_pgn(pgn);
  } catch (_) {
    loaded = false;
  }

  if (!loaded) {
    controller._engineOutput = 'PGN konnte nicht geladen werden.';
    _safeNotify(controller);
    return false;
  }

  controller._normalGameStartFen =
      startFen.isEmpty ? _defaultStartFen : startFen;
  controller._normalGameMoves
    ..clear()
    ..addAll(moves);

  _controllerClearNormalReview(controller);

  final lastMove = moves.isEmpty ? null : moves.last;

  controller
    .._selectedSquare = null
    .._lastFrom = lastMove?.from
    .._lastTo = lastMove?.to
    .._isBotThinking = false
    .._openingLogicAllowed = false
    .._resolvedRandomOpeningMove = null
    .._resultCountedForCurrentGame = false
    .._engineOutput = 'PGN geladen.'
    .._premoves.clear();

  if (markAnalysisUsed) {
    controller._analysisUsedDuringCurrentGame = true;
  }

  _safeNotify(controller);

  if (!controller.isGameOver && !controller.isPlayersTurn) {
    unawaited(_controllerMakeBotMoveIfNeeded(controller));
  }

  return true;
}

BoardMove? _boardMoveFromPgnHistoryEntry(dynamic entry) {
  if (entry is! Map) {
    return null;
  }

  final from = entry['from']?.toString().trim().toLowerCase() ?? '';
  final to = entry['to']?.toString().trim().toLowerCase() ?? '';

  if (!RegExp(r'^[a-h][1-8]$').hasMatch(from) ||
      !RegExp(r'^[a-h][1-8]$').hasMatch(to)) {
    return null;
  }

  return BoardMove(
    from: from,
    to: to,
    promotion: _pgnPromotionNotation(
      entry['promotion'],
      san: entry['san']?.toString(),
    ),
  );
}

String? _pgnPromotionNotation(
  dynamic value, {
  String? san,
}) {
  final text = value?.toString().trim().toLowerCase() ?? '';

  if (text == 'q' || text.endsWith('.queen') || text == 'queen') {
    return 'q';
  }

  if (text == 'r' || text.endsWith('.rook') || text == 'rook') {
    return 'r';
  }

  if (text == 'b' || text.endsWith('.bishop') || text == 'bishop') {
    return 'b';
  }

  if (text == 'n' || text.endsWith('.knight') || text == 'knight') {
    return 'n';
  }

  final sanPromotion = RegExp(
    r'=([QRBN])',
    caseSensitive: false,
  ).firstMatch(san ?? '');

  return sanPromotion?.group(1)?.toLowerCase();
}

bool _controllerTogglePlayFromHere(ChessBoardController controller) {
  if (controller.isPlayFromHereActive) {
    if (controller.isGameOver &&
        !controller._resultCountedForCurrentGame) {
      controller._resultCountedForCurrentGame = true;
    }

    controller._playFromHereFen = null;

    BetterBotsDatabase.instance.clearPlayFromHereMarker();
    _safeNotify(controller);
    return false;
  }

  final visibleFen = controller.fen.trim().replaceAll(RegExp(r'\s+'), ' ');
  final validationGame = chess.Chess();
  var loaded = false;

  try {
    loaded = validationGame.load(visibleFen);
  } catch (_) {
    loaded = false;
  }

  if (!loaded) {
    controller._engineOutput = 'Aktuelle Position konnte nicht markiert werden.';
    _safeNotify(controller);
    return false;
  }

  controller._playFromHereFen = visibleFen;

  BetterBotsDatabase.instance.savePlayFromHereMarker(visibleFen);
  _safeNotify(controller);
  return true;
}

