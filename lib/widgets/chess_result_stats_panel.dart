import 'package:flutter/material.dart';

class ChessResultStatsPanel extends StatelessWidget {
  const ChessResultStatsPanel({super.key});

  static const String placeholderValue = '[none]';
  static const Color wonColor = Color(0xFF55C878);
  static const Color lostColor = Color(0xFFFF5A5A);
  static const Color drawColor = Color(0xFF9A9A9A);
  static const Color trainedColor = Color(0xFFFFA726);

  static const List<ChessResultStatData> stats = [
    ChessResultStatData(
      title: 'Gewonnen',
      value: placeholderValue,
      titleColor: wonColor,
    ),
    ChessResultStatData(
      title: 'Verloren',
      value: placeholderValue,
      titleColor: lostColor,
    ),
    ChessResultStatData(
      title: 'Remis',
      value: placeholderValue,
      titleColor: drawColor,
    ),
    ChessResultStatData(
      title: 'Trainiert',
      value: placeholderValue,
      titleColor: trainedColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
  const ChessResultStatsTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          for (final stat in ChessResultStatsPanel.stats)
            _ResultStatText(data: stat),
        ],
      ),
    );
  }
}

class ChessResultStatData {
  const ChessResultStatData({
    required this.title,
    required this.value,
    required this.titleColor,
  });

  final String title;
  final String value;
  final Color titleColor;
}

class _ResultStatBox extends StatelessWidget {
  const _ResultStatBox({required this.data});

  final ChessResultStatData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withAlpha(190),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(28),
          width: 1,
        ),
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
                    color: data.titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStatText extends StatelessWidget {
  const _ResultStatText({required this.data});

  final ChessResultStatData data;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${data.title}: ',
            style: TextStyle(
              color: data.titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: data.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
