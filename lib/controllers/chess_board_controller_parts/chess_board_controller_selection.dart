part of chess_board_controller;

chess.Piece? _controllerPieceAt(
  ChessBoardController controller,
  String square,
) {
  if (!controller.isPlayersTurn && controller._premoves.isNotEmpty) {
    return _virtualPieceAt(controller, square);
  }

  return controller._game.get(square);
}

bool _controllerCanHumanMovePiece(
  ChessBoardController controller,
  String square,
) {
  if (controller.isGameOver) {
    return false;
  }

  if (controller.isPlayersTurn && !controller._isBotThinking) {
    final piece = controller._game.get(square);

    if (piece == null) {
      return false;
    }

    return _isOwnPiece(controller, piece);
  }

  if (!controller.isPlayersTurn) {
    final piece = _virtualPieceAt(controller, square);

    if (piece == null) {
      return false;
    }

    return _isPlayerPiece(controller, piece);
  }

  return false;
}

bool _controllerCanMoveTo(
  ChessBoardController controller, {
  required String from,
  required String to,
}) {
  if (controller.isGameOver) {
    return false;
  }

  if (from == to) {
    return false;
  }

  if (controller.isPlayersTurn && !controller._isBotThinking) {
    return _controllerLegalTargetsFromSquare(controller, from).contains(to);
  }

  if (!controller.isPlayersTurn) {
    final piece = _virtualPieceAt(controller, from);

    if (piece == null) {
      return false;
    }

    if (!_isPlayerPiece(controller, piece)) {
      return false;
    }

    final targetPiece = _virtualPieceAt(controller, to);

    if (targetPiece != null && _isPlayerPiece(controller, targetPiece)) {
      return false;
    }

    return true;
  }

  return false;
}

List<String> _controllerLegalTargetsForSelectedSquare(
  ChessBoardController controller,
) {
  if (controller._selectedSquare == null) {
    return [];
  }

  if (!controller.isPlayersTurn) {
    return [];
  }

  return _controllerLegalTargetsFromSquare(
    controller,
    controller._selectedSquare!,
  );
}

List<String> _controllerLegalTargetsFromSquare(
  ChessBoardController controller,
  String fromSquare,
) {
  final moves = controller._game.moves({'square': fromSquare, 'verbose': true});

  final targets = <String>[];

  for (final move in moves) {
    if (move is chess.Move) {
      targets.add(move.toAlgebraic);
    } else if (move is Map && move['to'] is String) {
      targets.add(move['to'] as String);
    }
  }

  return targets;
}
