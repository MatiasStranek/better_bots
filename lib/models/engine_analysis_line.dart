class EngineAnalysisLine {
  const EngineAnalysisLine({
    required this.rank,
    required this.depth,
    required this.uciMove,
    required this.pv,
    this.scoreCp,
    this.mate,
  });

  /// Engine-Rang aus MultiPV.
  /// 1 = beste Linie, 2 = zweitbeste Linie usw.
  final int rank;

  /// Suchtiefe, aus der diese Linie stammt.
  final int depth;

  /// Bewertung in Centipawns aus Sicht der Seite am Zug.
  final int? scoreCp;

  /// Mate-Distanz aus Sicht der Seite am Zug, falls Stockfish Mate meldet.
  final int? mate;

  /// Erster Zug der PV im UCI-Format, z. B. e2e4 oder e7e8q.
  final String uciMove;

  /// Vollständige Principal Variation als UCI-Zugliste.
  final List<String> pv;

  int get multiPv => rank;

  bool get hasMateScore => mate != null;

  bool get isValidMove {
    if (uciMove.length < 4) {
      return false;
    }

    if (uciMove == '(none)') {
      return false;
    }

    return true;
  }

  String get formattedEvaluation {
    final mateScore = mate;

    if (mateScore != null) {
      if (mateScore > 0) {
        return 'M$mateScore';
      }

      if (mateScore < 0) {
        return '-M${mateScore.abs()}';
      }

      return 'M0';
    }

    final cp = scoreCp ?? 0;
    final pawns = cp / 100.0;
    final prefix = pawns > 0 ? '+' : '';

    return '$prefix${pawns.toStringAsFixed(2)}';
  }

  String get pvText {
    if (pv.isEmpty) {
      return '-';
    }

    return pv.join(' ');
  }

  EngineAnalysisLine copyWith({
    int? rank,
    int? depth,
    int? scoreCp,
    int? mate,
    String? uciMove,
    List<String>? pv,
  }) {
    return EngineAnalysisLine(
      rank: rank ?? this.rank,
      depth: depth ?? this.depth,
      scoreCp: scoreCp ?? this.scoreCp,
      mate: mate ?? this.mate,
      uciMove: uciMove ?? this.uciMove,
      pv: pv ?? this.pv,
    );
  }

  @override
  String toString() {
    return 'EngineAnalysisLine('
        'rank: $rank, '
        'depth: $depth, '
        'scoreCp: $scoreCp, '
        'mate: $mate, '
        'uciMove: $uciMove, '
        'pv: $pv'
        ')';
  }
}
