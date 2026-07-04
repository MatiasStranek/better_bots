class BoardHighlights {
  const BoardHighlights({
    this.selectedSquare,
    this.lastFrom,
    this.lastTo,
    this.legalTargets = const [],
    this.premoveFrom,
    this.premoveTo,
  });

  final String? selectedSquare;
  final String? lastFrom;
  final String? lastTo;
  final List<String> legalTargets;

  final String? premoveFrom;
  final String? premoveTo;

  bool isSelected(String square) {
    return square == selectedSquare;
  }

  bool isLastMove(String square) {
    return square == lastFrom || square == lastTo;
  }

  bool isLegalTarget(String square) {
    return legalTargets.contains(square);
  }

  bool isPremove(String square) {
    return square == premoveFrom || square == premoveTo;
  }
}
