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
        const SizedBox(height: 8),
        if (analysisLines.isEmpty)
          SelectableText(
            isAnalysisThinking
                ? 'Engine analysiert bis Tiefe 20. Live-Linien erscheinen ab Tiefe 1 und werden nur nach abgeschlossenen Tiefen aktualisiert.'
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.green.shade200, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MoveBadge(label: line.displayMove),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '#${line.rank}  ${line.formattedEvaluation}  Tiefe ${line.depth}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (line.pv.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SelectableText(
                    'PV: ${line.pvText}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveBadge extends StatelessWidget {
  const _MoveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = label.trim().isEmpty ? '-' : label.trim();

    return Container(
      constraints: const BoxConstraints(minWidth: 42, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade500, width: 1.4),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '[$text]',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.green.shade800,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
