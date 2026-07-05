part of chess_board_controller;

chess.Piece? _virtualPieceAt(ChessBoardController controller, String square) {
  return _virtualBoardAfterPremoves(controller)[square];
}

Map<String, chess.Piece> _virtualBoardAfterPremoves(
  ChessBoardController controller,
) {
  final board = <String, chess.Piece>{};

  for (final square in _allSquares()) {
    final piece = controller._game.get(square);

    if (piece != null) {
      board[square] = piece;
    }
  }

  for (final move in controller._premoves.moves) {
    final piece = board.remove(move.from);

    if (piece == null) {
      break;
    }

    if (!_isPlayerPiece(controller, piece)) {
      break;
    }

    board[move.to] = _pieceAfterVirtualMove(piece: piece, move: move);
  }

  return board;
}

chess.Piece _pieceAfterVirtualMove({
  required chess.Piece piece,
  required BoardMove move,
}) {
  final promotion = move.promotion;

  if (promotion == null || promotion.isEmpty) {
    return piece;
  }

  if (!_isPawn(piece)) {
    return piece;
  }

  return chess.Piece(_pieceTypeForPromotion(promotion), piece.color);
}

List<String> _allSquares() {
  const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  const ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

  final squares = <String>[];

  for (final file in files) {
    for (final rank in ranks) {
      squares.add('$file$rank');
    }
  }

  return squares;
}
