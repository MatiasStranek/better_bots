class BoardArrowAnnotation {
  const BoardArrowAnnotation({required this.from, required this.to});

  final String from;
  final String to;

  bool get isKnightMove {
    if (from.length != 2 || to.length != 2) {
      return false;
    }

    final fromFile = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toFile = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRank = int.tryParse(from.substring(1, 2));
    final toRank = int.tryParse(to.substring(1, 2));

    if (fromRank == null || toRank == null) {
      return false;
    }

    final fileDelta = (toFile - fromFile).abs();
    final rankDelta = (toRank - fromRank).abs();

    return (fileDelta == 1 && rankDelta == 2) ||
        (fileDelta == 2 && rankDelta == 1);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardArrowAnnotation &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}
