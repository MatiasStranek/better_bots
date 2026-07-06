import 'package:flutter/material.dart';

import '../../models/engine_analysis_line.dart';
import '../../models/player_side.dart';

class ChessBoardDebugPanel extends StatelessWidget {
  const ChessBoardDebugPanel({
    required this.playerSide,
    required this.fen,
    required this.pgn,
    required this.engineOutput,
    required this.isAnalysisMode,
    required this.isAnalysisThinking,
    required this.analysisLines,
    super.key,
  });

  final PlayerSide playerSide;
  final String fen;
  final String pgn;
  final String engineOutput;
  final bool isAnalysisMode;
  final bool isAnalysisThinking;
  final List<EngineAnalysisLine> analysisLines;

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
        if (isAnalysisMode)
          _AnalysisLinesView(
            isAnalysisThinking: isAnalysisThinking,
            analysisLines: analysisLines,
          )
        else ...[
          Text(
            'Letzte Engine-Ausgabe:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SelectableText(engineOutput),
        ],
      ],
    );
  }
}

class _AnalysisLinesView extends StatelessWidget {
  const _AnalysisLinesView({
    required this.isAnalysisThinking,
    required this.analysisLines,
  });

  final bool isAnalysisThinking;
  final List<EngineAnalysisLine> analysisLines;

  @override
  Widget build(BuildContext context) {
    final titleSuffix = isAnalysisThinking ? ' läuft...' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top-5 Analyse$titleSuffix',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (analysisLines.isEmpty)
          SelectableText(
            isAnalysisThinking
                ? 'Engine analysiert bis Tiefe 20.'
                : 'Noch keine Analyse-Linien vorhanden.',
          )
        else
          ...analysisLines.map((line) => _AnalysisLineTile(line: line)),
      ],
    );
  }
}

class _AnalysisLineTile extends StatelessWidget {
  const _AnalysisLineTile({required this.line});

  final EngineAnalysisLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            '#${line.rank}  ${line.formattedEvaluation}  '
            '${line.uciMove}  Tiefe ${line.depth}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (line.pv.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SelectableText(
                'PV: ${line.pvText}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
