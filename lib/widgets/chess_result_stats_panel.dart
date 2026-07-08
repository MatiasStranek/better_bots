import 'package:flutter/material.dart';

import '../data/better_bots_database.dart';

class ChessResultStatsPanel extends StatelessWidget {
  const ChessResultStatsPanel({
    super.key,
    this.counter = const TrainingCounterSnapshot.zero(),
  });

  static const Color wonColor = Color(0xFF55C878);
  static const Color lostColor = Color(0xFFFF5A5A);
  static const Color drawColor = Color(0xFF9A9A9A);
  static const Color trainedColor = Color(0xFFFFA726);

  final TrainingCounterSnapshot counter;

  bool get _hasWonWithBothColors {
    return counter.wonWhiteCount >= 1 && counter.wonBlackCount >= 1;
  }

  List<ChessResultStatData> get _stats {
    return [
      ChessResultStatData(
        title: 'Gewonnen',
        value: '${counter.wonCount}',
        whiteCount: counter.wonWhiteCount,
        blackCount: counter.wonBlackCount,
        titleColor: wonColor,
        useCompletionGradient: _hasWonWithBothColors,
      ),
      ChessResultStatData(
        title: 'Verloren',
        value: '${counter.lostCount}',
        whiteCount: counter.lostWhiteCount,
        blackCount: counter.lostBlackCount,
        titleColor: lostColor,
      ),
      ChessResultStatData(
        title: 'Remis',
        value: '${counter.drawCount}',
        whiteCount: counter.drawWhiteCount,
        blackCount: counter.drawBlackCount,
        titleColor: drawColor,
      ),
      ChessResultStatData(
        title: 'Trainiert',
        value: '${counter.trainedCount}',
        whiteCount: counter.trainedWhiteCount,
        blackCount: counter.trainedBlackCount,
        titleColor: trainedColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          Expanded(child: _ResultStatBox(data: stats[index])),
          if (index < stats.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class ChessResultStatsTextView extends StatelessWidget {
  const ChessResultStatsTextView({
    super.key,
    this.counter = const TrainingCounterSnapshot.zero(),
    required this.analysisUsedDuringCurrentGame,
  });

  final TrainingCounterSnapshot counter;
  final bool analysisUsedDuringCurrentGame;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChessResultStatsPanel(counter: counter),
        const SizedBox(height: 8),
        _AnalysisUsageBadge(
          analysisUsedDuringCurrentGame: analysisUsedDuringCurrentGame,
        ),
      ],
    );
  }
}


class _AnalysisUsageBadge extends StatelessWidget {
  const _AnalysisUsageBadge({required this.analysisUsedDuringCurrentGame});

  final bool analysisUsedDuringCurrentGame;

  @override
  Widget build(BuildContext context) {
    final hasCleanGame = !analysisUsedDuringCurrentGame;
    final color = hasCleanGame
        ? const Color(0xFF55C878)
        : const Color(0xFFFF5A5A);
    final icon = hasCleanGame ? '✓' : '✕';
    final label = hasCleanGame
        ? 'Analyse nicht benutzt'
        : 'Analyse benutzt';

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(190),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(155), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChessResultStatData {
  const ChessResultStatData({
    required this.title,
    required this.value,
    required this.whiteCount,
    required this.blackCount,
    required this.titleColor,
    this.useCompletionGradient = false,
  });

  final String title;
  final String value;
  final int whiteCount;
  final int blackCount;
  final Color titleColor;
  final bool useCompletionGradient;
}

class _ResultStatBox extends StatelessWidget {
  const _ResultStatBox({required this.data});

  final ChessResultStatData data;

  @override
  Widget build(BuildContext context) {
    final usesGradient = data.useCompletionGradient;

    return Semantics(
      button: true,
      label: '${data.title}: ${data.value}. Details anzeigen.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showResultStatBreakdownDialog(context, data),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: usesGradient ? null : const Color(0xFF111111).withAlpha(190),
            gradient: usesGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F7A3A),
                      Color(0xFF25B65B),
                      Color(0xFF7EF2A4),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: usesGradient
                  ? Colors.white.withAlpha(92)
                  : Colors.white.withAlpha(28),
              width: usesGradient ? 1.4 : 1,
            ),
            boxShadow: usesGradient
                ? [
                    BoxShadow(
                      color: const Color(0xFF25B65B).withAlpha(95),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: usesGradient ? Colors.white : data.titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        shadows: usesGradient
                            ? const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ]
                            : const [],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showResultStatBreakdownDialog(
  BuildContext context,
  ChessResultStatData data,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(data.title),
        content: _ResultStatBreakdownContent(data: data),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class _ResultStatBreakdownContent extends StatelessWidget {
  const _ResultStatBreakdownContent({required this.data});

  final ChessResultStatData data;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BreakdownLine(
            label: 'Mit Weiß',
            value: data.whiteCount,
            color: data.titleColor,
          ),
          const SizedBox(height: 8),
          _BreakdownLine(
            label: 'Mit Schwarz',
            value: data.blackCount,
            color: data.titleColor,
          ),
          const SizedBox(height: 14),
          Text(
            'Gesamt: ${data.value}',
            style: TextStyle(
              color: data.titleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
