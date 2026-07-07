import 'package:flutter/material.dart';

import '../../../models/engine_analysis_line.dart';

class MobileChessAnalysisLinesBar extends StatelessWidget {
  const MobileChessAnalysisLinesBar({
    super.key,
    required this.analysisLines,
  });

  final List<EngineAnalysisLine> analysisLines;

  static const int _maxVisibleLines = 5;
  static const Color _boxColor = Color(0xFF2E8F4F);
  static const Color _bestBoxColor = Color(0xFF39A95C);

  @override
  Widget build(BuildContext context) {
    final visibleLines = analysisLines
        .where((line) => line.isValidMove)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_maxVisibleLines, (index) {
        final line = index < visibleLines.length ? visibleLines[index] : null;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == _maxVisibleLines - 1 ? 0 : 4,
            ),
            child: _AnalysisMoveColumn(
              rank: index + 1,
              line: line,
              isBestMove: index == 0,
            ),
          ),
        );
      }),
    );
  }
}

class _AnalysisMoveColumn extends StatelessWidget {
  const _AnalysisMoveColumn({
    required this.rank,
    required this.line,
    required this.isBestMove,
  });

  final int rank;
  final EngineAnalysisLine? line;
  final bool isBestMove;

  String get _evaluationText {
    final analysisLine = line;

    if (analysisLine == null) {
      return '...';
    }

    final mateScore = analysisLine.mate;

    if (mateScore != null) {
      if (mateScore > 0) {
        return 'M$mateScore';
      }

      if (mateScore < 0) {
        return '-M${mateScore.abs()}';
      }

      return 'M0';
    }

    final scoreCp = analysisLine.scoreCp ?? 0;

    if (scoreCp == 0) {
      return '0';
    }

    final pawns = scoreCp / 100.0;
    final prefix = pawns > 0 ? '+' : '';

    return '$prefix${pawns.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          height: 18,
          child: Center(
            child: Text(
              _evaluationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _AnalysisMoveBox(
            rank: rank,
            line: line,
            isBestMove: isBestMove,
          ),
        ),
      ],
    );
  }
}

class _AnalysisMoveBox extends StatelessWidget {
  const _AnalysisMoveBox({
    required this.rank,
    required this.line,
    required this.isBestMove,
  });

  final int rank;
  final EngineAnalysisLine? line;
  final bool isBestMove;

  static const Color _boxColor = MobileChessAnalysisLinesBar._boxColor;
  static const Color _bestBoxColor = MobileChessAnalysisLinesBar._bestBoxColor;

  @override
  Widget build(BuildContext context) {
    final moveText = line?.displayMove ?? '...';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isBestMove ? _bestBoxColor : _boxColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#$rank',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              moveText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
