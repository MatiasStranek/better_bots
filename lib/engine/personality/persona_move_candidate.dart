class PersonaMoveCandidate {
  const PersonaMoveCandidate({
    required this.uciMove,
    required this.multiPv,
    required this.scoreCp,
    required this.depth,
    required this.pv,
  });

  /// Der eigentliche Zug im UCI-Format, z. B. e2e4, g1f3, e7e8q.
  final String uciMove;

  /// MultiPV-Rang aus Stockfish:
  /// 1 = objektiv bester Kandidat, 2 = zweitbester Kandidat usw.
  final int multiPv;

  /// Bewertung in Centipawns aus Sicht der Seite am Zug.
  ///
  /// Positive Werte bedeuten: gut für die Seite, die gerade zieht.
  /// Mate-Wertungen werden in große Centipawn-Werte umgerechnet.
  final int scoreCp;

  /// Suchtiefe, aus der dieser Kandidat stammt.
  final int depth;

  /// Die vollständige Principal Variation als UCI-Zugliste.
  final List<String> pv;

  int centipawnLossComparedTo(PersonaMoveCandidate bestCandidate) {
    return bestCandidate.scoreCp - scoreCp;
  }

  bool get isValidMove {
    if (uciMove.length < 4) {
      return false;
    }

    if (uciMove == '(none)') {
      return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'PersonaMoveCandidate('
        'uciMove: $uciMove, '
        'multiPv: $multiPv, '
        'scoreCp: $scoreCp, '
        'depth: $depth, '
        'pv: $pv'
        ')';
  }
}
