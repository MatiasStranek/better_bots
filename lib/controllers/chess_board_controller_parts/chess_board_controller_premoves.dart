part of chess_board_controller;

Future<void> _onPremoveSquareTap(
  ChessBoardController controller,
  String square,
) async {
  final piece = _virtualPieceAt(controller, square);

  if (controller._selectedSquare == null) {
    if (piece == null) {
      _clearPremoves(controller);
      return;
    }

    if (!_isPlayerPiece(controller, piece)) {
      return;
    }

    _controllerSelectSquare(controller, square);
    return;
  }

  if (controller._selectedSquare == square) {
    _controllerClearSelectedSquare(controller);
    return;
  }

  if (piece != null && _isPlayerPiece(controller, piece)) {
    _controllerSelectSquare(controller, square);
    return;
  }

  await _addPremove(controller, from: controller._selectedSquare!, to: square);
}

Future<bool> _addPremove(
  ChessBoardController controller, {
  required String from,
  required String to,
  String? promotion,
}) async {
  if (from == to || controller.isGameOver) {
    return false;
  }

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

  final selectedPromotion = await _promotionForMoveIfNeeded(
    controller,
    from: from,
    to: to,
    promotion: promotion,
    useVirtualBoard: true,
  );

  if (selectedPromotion == null) {
    _controllerClearSelectedSquare(controller);
    return false;
  }

  controller._premoves.add(
    BoardMove(
      from: from,
      to: to,
      promotion: selectedPromotion.isEmpty ? null : selectedPromotion,
    ),
  );

  controller._selectedSquare = null;

  _safeNotify(controller);

  return true;
}

void _clearPremoves(ChessBoardController controller) {
  if (controller._premoves.isEmpty && controller._selectedSquare == null) {
    return;
  }

  controller._premoves.clear();
  controller._selectedSquare = null;

  _safeNotify(controller);
}

Future<void> _tryPlayNextPremoveIfPossible(
  ChessBoardController controller,
) async {
  if (controller._premoves.isEmpty) {
    return;
  }

  if (controller.isGameOver || !controller.isPlayersTurn) {
    _safeNotify(controller);
    return;
  }

  final premove = controller._premoves.popFirst();

  if (premove == null) {
    return;
  }

  final moveData = <String, String>{'from': premove.from, 'to': premove.to};

  if (premove.promotion != null && premove.promotion!.isNotEmpty) {
    moveData['promotion'] = premove.promotion!;
  }

  final moved = controller._game.move(moveData);

  if (!moved) {
    controller._premoves.clear();
    controller._selectedSquare = null;
    controller._engineOutput =
        'Premove ungültig: '
        '${premove.from}-${premove.to}. Weitere Premoves gelöscht.';
    _safeNotify(controller);
    return;
  }

  controller._lastFrom = premove.from;
  controller._lastTo = premove.to;
  controller._selectedSquare = null;

  _safeNotify(controller);

  await _controllerMakeBotMoveIfNeeded(controller);
}
