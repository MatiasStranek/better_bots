import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../data/better_bots_database.dart';
import '../../models/engine_analysis_line.dart';
import '../../models/player_side.dart';
import '../../ui/mobile/widgets/mobile_chess_analysis_lines_bar.dart';
import '../chess_result_stats_panel.dart';

class ChessBoardDebugPanel extends StatelessWidget {
  const ChessBoardDebugPanel({
    required this.playerSide,
    required this.fen,
    required this.pgn,
    required this.engineOutput,
    required this.isAnalysisMode,
    required this.isAnalysisThinking,
    required this.analysisLines,
    required this.trainingCounter,
    required this.analysisUsedDuringCurrentGame,
    required this.trainedOnly,
    super.key,
  });

  final PlayerSide playerSide;
  final String fen;
  final String pgn;
  final String engineOutput;
  final bool isAnalysisMode;
  final bool isAnalysisThinking;
  final List<EngineAnalysisLine> analysisLines;
  final TrainingCounterSnapshot trainingCounter;
  final bool analysisUsedDuringCurrentGame;
  final bool trainedOnly;

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
        ChessResultStatsTextView(
          counter: trainingCounter,
          analysisUsedDuringCurrentGame: analysisUsedDuringCurrentGame,
          trainedOnly: trainedOnly,
        ),
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
          const SizedBox(height: 4),
          SelectableText(engineOutput),
        ],
        const SizedBox(height: 16),
        _LabeledSelectableBlock(
          label: 'FEN:',
          value: fen,
        ),
        const SizedBox(height: 12),
        _LabeledSelectableBlock(
          label: 'PGN:',
          value: pgn,
        ),
      ],
    );
  }
}

class _LabeledSelectableBlock extends StatelessWidget {
  const _LabeledSelectableBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
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
    final headerDepth = _resolveHeaderDepth();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Top-5 Analyse$titleSuffix',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (headerDepth != null) ...[
              const SizedBox(width: 18),
              Text(
                'Tiefe $headerDepth',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (analysisLines.isEmpty)
          SelectableText(
            isAnalysisThinking
                ? 'Engine analysiert bis Tiefe 20. Live-Linien erscheinen ab Tiefe 1 und werden nur nach abgeschlossenen Tiefen aktualisiert.'
                : 'Noch keine Analyse-Linien vorhanden.',
          )
        else
          _DesktopAnalysisLinesBar(analysisLines: analysisLines),
      ],
    );
  }

  int? _resolveHeaderDepth() {
    if (analysisLines.isEmpty) {
      return null;
    }

    var maxDepth = analysisLines.first.depth;
    for (final line in analysisLines.skip(1)) {
      if (line.depth > maxDepth) {
        maxDepth = line.depth;
      }
    }

    return maxDepth;
  }
}

class _DesktopAnalysisLinesBar extends StatelessWidget {
  const _DesktopAnalysisLinesBar({required this.analysisLines});

  final List<EngineAnalysisLine> analysisLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      width: double.infinity,
      child: MobileChessAnalysisLinesBar(analysisLines: analysisLines),
    );
  }
}
