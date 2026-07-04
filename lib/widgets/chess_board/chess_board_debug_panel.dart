import 'package:flutter/material.dart';

import '../../models/player_side.dart';

class ChessBoardDebugPanel extends StatelessWidget {
  const ChessBoardDebugPanel({
    required this.playerSide,
    required this.fen,
    required this.pgn,
    required this.engineOutput,
    super.key,
  });

  final PlayerSide playerSide;
  final String fen;
  final String pgn;
  final String engineOutput;

  @override
  Widget build(BuildContext context) {
    final playerSideText = playerSide == PlayerSide.white ? 'Weiß' : 'Schwarz';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Du spielst: $playerSideText',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text('FEN:', style: Theme.of(context).textTheme.titleSmall),
        SelectableText(fen),
        const SizedBox(height: 12),
        Text('PGN:', style: Theme.of(context).textTheme.titleSmall),
        SelectableText(pgn),
        const SizedBox(height: 12),
        Text(
          'Letzte Engine-Ausgabe:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SelectableText(engineOutput),
      ],
    );
  }
}
