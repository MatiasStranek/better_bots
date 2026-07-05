class BoardHighlights {
  const BoardHighlights({
    this.selectedSquare,
    this.lastFrom,
    this.lastTo,
    this.premoveSquares = const {},
    this.legalTargets = const [],
  });

  final String? selectedSquare;
  final String? lastFrom;
  final String? lastTo;

  final Set<String> premoveSquares;

  final List<String> legalTargets;

  bool isSelected(String square) {
    return selectedSquare == square;
  }

  bool isLastMove(String square) {
    return square == lastFrom || square == lastTo;
  }

  bool isPremove(String square) {
    return premoveSquares.contains(square);
  }

  bool isLegalTarget(String square) {
    return legalTargets.contains(square);
  }
}
