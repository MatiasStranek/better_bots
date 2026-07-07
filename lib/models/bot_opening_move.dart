enum BotOpeningMove {
  none(label: 'Ohne Eröffnung', whiteUci: null, blackUci: null),
  random(label: 'Zufällig', whiteUci: null, blackUci: null),

  a4a5(label: 'a4 || a5', whiteUci: 'a2a4', blackUci: 'a7a5'),
  b4b5(label: 'b4 || b5', whiteUci: 'b2b4', blackUci: 'b7b5'),
  c4c5(label: 'c4 || c5', whiteUci: 'c2c4', blackUci: 'c7c5'),
  d4d5(label: 'd4 || d5', whiteUci: 'd2d4', blackUci: 'd7d5'),
  e4e5(label: 'e4 || e5', whiteUci: 'e2e4', blackUci: 'e7e5'),
  f4f5(label: 'f4 || f5', whiteUci: 'f2f4', blackUci: 'f7f5'),
  g4g5(label: 'g4 || g5', whiteUci: 'g2g4', blackUci: 'g7g5'),
  h4h5(label: 'h4 || h5', whiteUci: 'h2h4', blackUci: 'h7h5'),

  a3a6(label: 'a3 || a6', whiteUci: 'a2a3', blackUci: 'a7a6'),
  b3b6(label: 'b3 || b6', whiteUci: 'b2b3', blackUci: 'b7b6'),
  c3c6(label: 'c3 || c6', whiteUci: 'c2c3', blackUci: 'c7c6'),
  d3d6(label: 'd3 || d6', whiteUci: 'd2d3', blackUci: 'd7d6'),
  e3e6(label: 'e3 || e6', whiteUci: 'e2e3', blackUci: 'e7e6'),
  f3f6(label: 'f3 || f6', whiteUci: 'f2f3', blackUci: 'f7f6'),
  g3g6(label: 'g3 || g6', whiteUci: 'g2g3', blackUci: 'g7g6'),
  h3h6(label: 'h3 || h6', whiteUci: 'h2h3', blackUci: 'h7h6'),

  na3na6(label: 'Na3 || Na6', whiteUci: 'b1a3', blackUci: 'b8a6'),
  nc3nc6(label: 'Nc3 || Nc6', whiteUci: 'b1c3', blackUci: 'b8c6'),
  nf3nf6(label: 'Nf3 || Nf6', whiteUci: 'g1f3', blackUci: 'g8f6'),
  nh3nh6(label: 'Nh3 || Nh6', whiteUci: 'g1h3', blackUci: 'g8h6');

  const BotOpeningMove({
    required this.label,
    required this.whiteUci,
    required this.blackUci,
  });

  final String label;
  final String? whiteUci;
  final String? blackUci;

  bool get isRealOpening {
    return this != BotOpeningMove.none && this != BotOpeningMove.random;
  }

  static List<BotOpeningMove> get realOpenings {
    return values
        .where((move) => move.isRealOpening)
        .toList();
  }
}
