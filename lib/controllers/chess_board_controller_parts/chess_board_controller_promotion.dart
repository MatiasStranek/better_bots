part of chess_board_controller;

Future<String?> _promotionForMoveIfNeeded(
  ChessBoardController controller, {
  required String from,
  required String to,
  required bool useVirtualBoard,
  String? promotion,
}) async {
  if (!_isPromotionMove(
    controller,
    from: from,
    to: to,
    useVirtualBoard: useVirtualBoard,
  )) {
    return '';
  }

  if (promotion != null && promotion.isNotEmpty) {
    return _normalizePromotion(promotion);
  }

  if (controller._onPromotionChoiceRequested == null) {
    return 'q';
  }

  final choice = await controller._onPromotionChoiceRequested!(
    from: from,
    to: to,
    playerSide: controller._playerSide,
  );

  if (choice == null || choice.isEmpty) {
    return null;
  }

  return _normalizePromotion(choice);
}

bool _isPromotionMove(
  ChessBoardController controller, {
  required String from,
  required String to,
  required bool useVirtualBoard,
}) {
  final piece = useVirtualBoard
      ? _virtualPieceAt(controller, from)
      : controller._game.get(from);

  if (piece == null) {
    return false;
  }

  if (!_isPawn(piece)) {
    return false;
  }

  final targetRank = to.substring(1, 2);

  if (piece.color == chess.Color.WHITE) {
    return targetRank == '8';
  }

  return targetRank == '1';
}

bool _isPawn(chess.Piece piece) {
  final typeText = piece.type.toString().toLowerCase();

  return typeText == 'p' ||
      typeText.endsWith('.p') ||
      typeText.contains('pawn');
}

String _normalizePromotion(String promotion) {
  final normalized = promotion.toLowerCase();

  if (normalized == 'q' ||
      normalized == 'r' ||
      normalized == 'b' ||
      normalized == 'n') {
    return normalized;
  }

  return 'q';
}

chess.PieceType _pieceTypeForPromotion(String promotion) {
  final normalized = _normalizePromotion(promotion);

  switch (normalized) {
    case 'r':
      return chess.PieceType.ROOK;
    case 'b':
      return chess.PieceType.BISHOP;
    case 'n':
      return chess.PieceType.KNIGHT;
    case 'q':
    default:
      return chess.PieceType.QUEEN;
  }
}
