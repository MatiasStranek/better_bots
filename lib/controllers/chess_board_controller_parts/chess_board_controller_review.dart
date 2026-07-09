part of chess_board_controller;

class ChessMoveListEntry {
  const ChessMoveListEntry({
    required this.ply,
    required this.fullMoveNumber,
    required this.isWhiteMove,
    required this.san,
  });

  /// Halbzug-Index nach diesem Zug. Beispiel: 1 = nach Weiß' erstem Zug.
  final int ply;
  final int fullMoveNumber;
  final bool isWhiteMove;
  final String san;
}

bool _controllerIsNormalReviewMode(ChessBoardController controller) {
  return controller._analysisSession == null &&
      controller._normalReviewPly != null;
}

int _controllerCurrentMainLinePly(ChessBoardController controller) {
  if (controller._analysisSession != null) {
    return _clampMainLinePly(
      controller,
      controller._analysisMainLinePly ??
          controller._normalReviewPlyBeforeAnalysis ??
          controller._normalReviewPly ??
          controller._normalGameMoves.length,
    );
  }

  return _clampMainLinePly(
    controller,
    controller._normalReviewPly ?? controller._normalGameMoves.length,
  );
}

bool _controllerCanUseNormalMainLineNavigation(
  ChessBoardController controller,
) {
  if (controller._analysisSession != null || controller._isBotThinking) {
    return false;
  }

  // Wenn wir bereits eine vergangene Stellung betrachten, darf man weiter in
  // der Mainline navigieren. Figuren bleiben dort trotzdem gesperrt.
  if (_controllerIsNormalReviewMode(controller)) {
    return true;
  }

  // Nach Partieende darf man die gespielte Partie ebenfalls durchgehen.
  if (controller._game.game_over ||
      controller._game.in_checkmate ||
      controller._game.in_stalemate ||
      controller._game.in_draw) {
    return true;
  }

  // Im Live-Spiel darf man nur dann in die Vergangenheit springen, wenn der
  // Mensch am Zug ist. Während der Gegner/Bot am Zug ist, bleibt Review aus.
  final whiteToMove = controller._game.turn == chess.Color.WHITE;

  return controller.playerIsWhite ? whiteToMove : !whiteToMove;
}

bool _controllerCanNavigateMainLineBack(ChessBoardController controller) {
  if (!_controllerCanUseNormalMainLineNavigation(controller)) {
    return false;
  }

  return _controllerCurrentMainLinePly(controller) > 0;
}

bool _controllerCanNavigateMainLineForward(ChessBoardController controller) {
  if (!_controllerCanUseNormalMainLineNavigation(controller)) {
    return false;
  }

  final reviewPly = controller._normalReviewPly;

  return reviewPly != null && reviewPly < controller._normalGameMoves.length;
}

void _controllerStepMainLineBack(ChessBoardController controller) {
  if (!_controllerCanNavigateMainLineBack(controller)) {
    return;
  }

  final currentPly = _controllerCurrentMainLinePly(controller);
  _controllerSetNormalReviewPly(controller, currentPly - 1);
}

void _controllerStepMainLineForward(ChessBoardController controller) {
  if (!_controllerCanNavigateMainLineForward(controller)) {
    return;
  }

  final currentPly = _controllerCurrentMainLinePly(controller);
  _controllerSetNormalReviewPly(controller, currentPly + 1);
}


void _controllerJumpMainLineToStart(ChessBoardController controller) {
  if (!_controllerCanNavigateMainLineBack(controller)) {
    return;
  }

  _controllerSetNormalReviewPly(controller, 0);
}

void _controllerJumpMainLineToEnd(ChessBoardController controller) {
  if (!_controllerCanNavigateMainLineForward(controller)) {
    return;
  }

  _controllerSetNormalReviewPly(controller, controller._normalGameMoves.length);
}

Future<void> _controllerJumpToMainLinePly(
  ChessBoardController controller,
  int ply,
) async {
  final session = controller._analysisSession;

  if (session == null &&
      !_controllerCanUseNormalMainLineNavigation(controller)) {
    return;
  }

  if (session != null && controller._isBotThinking) {
    return;
  }

  final targetPly = _clampMainLinePly(controller, ply);

  if (session != null) {
    final jumped = session.jumpToStart();

    if (!jumped && targetPly == 0) {
      return;
    }

    for (var index = 0; index < targetPly; index++) {
      if (!session.stepForward()) {
        break;
      }
    }

    controller._analysisMainLinePly = targetPly;
    controller._selectedSquare = null;
    _safeNotify(controller);
    _requestAnalysisForCurrentPosition(controller);
    return;
  }

  _controllerSetNormalReviewPly(controller, targetPly);
}

void _controllerSetNormalReviewPly(
  ChessBoardController controller,
  int ply,
) {
  final targetPly = _clampMainLinePly(controller, ply);

  if (targetPly >= controller._normalGameMoves.length) {
    if (controller._normalReviewPly == null) {
      return;
    }

    controller._normalReviewPly = null;
  } else {
    if (controller._normalReviewPly == targetPly) {
      return;
    }

    controller._normalReviewPly = targetPly;
  }

  controller._selectedSquare = null;
  controller._premoves.clear();

  _safeNotify(controller);
}

int _clampMainLinePly(ChessBoardController controller, int ply) {
  return ply.clamp(0, controller._normalGameMoves.length).toInt();
}

chess.Chess _controllerDisplayedNormalGame(
  ChessBoardController controller,
) {
  final reviewPly = controller._normalReviewPly;

  if (reviewPly == null) {
    return controller._game;
  }

  return _replayNormalGameToPly(controller, reviewPly);
}

String _controllerDisplayedNormalFen(ChessBoardController controller) {
  return _controllerDisplayedNormalGame(controller).fen;
}

chess.Piece? _controllerDisplayedNormalPieceAt(
  ChessBoardController controller,
  String square,
) {
  return _controllerDisplayedNormalGame(controller).get(square);
}

BoardMove? _controllerLastDisplayedNormalMove(
  ChessBoardController controller,
) {
  final reviewPly = controller._normalReviewPly;

  if (reviewPly == null) {
    if (controller._normalGameMoves.isEmpty) {
      return null;
    }

    return controller._normalGameMoves.last;
  }

  if (reviewPly <= 0 || reviewPly > controller._normalGameMoves.length) {
    return null;
  }

  return controller._normalGameMoves[reviewPly - 1];
}

chess.Chess _replayNormalGameToPly(
  ChessBoardController controller,
  int ply,
) {
  final game = chess.Chess();
  var loaded = false;

  try {
    loaded = game.load(controller._normalGameStartFen);
  } catch (_) {
    loaded = false;
  }

  if (!loaded) {
    return game;
  }

  final targetPly = _clampMainLinePly(controller, ply);

  for (final move in controller._normalGameMoves.take(targetPly)) {
    final moved = _applyBoardMoveToChessGame(game, move);

    if (!moved) {
      break;
    }
  }

  return game;
}

bool _applyBoardMoveToChessGame(chess.Chess game, BoardMove move) {
  final moveData = <String, String>{'from': move.from, 'to': move.to};
  final promotion = move.promotion;

  if (promotion != null && promotion.isNotEmpty) {
    moveData['promotion'] = promotion;
  }

  return game.move(moveData);
}

List<ChessMoveListEntry> _controllerMainLineMoveEntries(
  ChessBoardController controller,
) {
  final game = chess.Chess();
  var loaded = false;

  try {
    loaded = game.load(controller._normalGameStartFen);
  } catch (_) {
    loaded = false;
  }

  if (!loaded) {
    return const [];
  }

  final entries = <ChessMoveListEntry>[];

  for (var index = 0; index < controller._normalGameMoves.length; index++) {
    final move = controller._normalGameMoves[index];
    final beforeFen = game.fen;
    final beforeParts = beforeFen.trim().split(RegExp(r'\s+'));
    final isWhiteMove = beforeParts.length >= 2
        ? beforeParts[1] == 'w'
        : index.isEven;
    final fullMoveNumber = beforeParts.length >= 6
        ? int.tryParse(beforeParts[5]) ?? ((index ~/ 2) + 1)
        : ((index ~/ 2) + 1);
    final moved = _applyBoardMoveToChessGame(game, move);

    if (!moved) {
      break;
    }

    final san = _lastSanFromPgn(game.pgn()) ?? _boardMoveDisplayText(move);

    entries.add(
      ChessMoveListEntry(
        ply: index + 1,
        fullMoveNumber: fullMoveNumber,
        isWhiteMove: isWhiteMove,
        san: san,
      ),
    );
  }

  return entries;
}

String? _lastSanFromPgn(String pgn) {
  final cleanPgn = pgn
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .trim();

  if (cleanPgn.isEmpty || cleanPgn == '-') {
    return null;
  }

  final tokens = cleanPgn.split(RegExp(r'\s+'));

  for (var index = tokens.length - 1; index >= 0; index--) {
    final token = tokens[index].trim();

    if (token.isEmpty ||
        token == '*' ||
        token == '1-0' ||
        token == '0-1' ||
        token == '1/2-1/2' ||
        RegExp(r'^\d+\.(\.\.)?$').hasMatch(token)) {
      continue;
    }

    return token;
  }

  return null;
}

String _boardMoveDisplayText(BoardMove move) {
  final promotion = move.promotion;

  if (promotion != null && promotion.isNotEmpty) {
    return '${move.from}${move.to}=${promotion.toUpperCase()}';
  }

  return '${move.from}${move.to}';
}


void _controllerClearNormalReview(ChessBoardController controller) {
  controller._normalReviewPly = null;
  controller._normalReviewPlyBeforeAnalysis = null;
  controller._analysisMainLinePly = null;
}
