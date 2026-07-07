import 'package:flutter/material.dart';

class MobileChessResultStatsPanel extends StatelessWidget {
  const MobileChessResultStatsPanel({super.key});

  static const String _placeholderValue = '[none]';
  static const Color _wonColor = Color(0xFF55C878);
  static const Color _lostColor = Color(0xFFFF5A5A);
  static const Color _drawColor = Colors.white;
  static const Color _playedColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ResultStatBox(
            title: 'Gewonnen',
            titleColor: _wonColor,
            value: _placeholderValue,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _ResultStatBox(
            title: 'Verloren',
            titleColor: _lostColor,
            value: _placeholderValue,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _ResultStatBox(
            title: 'Remis',
            titleColor: _drawColor,
            value: _placeholderValue,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _ResultStatBox(
            title: 'Gespielt',
            titleColor: _playedColor,
            value: _placeholderValue,
          ),
        ),
      ],
    );
  }
}

class _ResultStatBox extends StatelessWidget {
  const _ResultStatBox({
    required this.title,
    required this.titleColor,
    required this.value,
  });

  final String title;
  final Color titleColor;
  final String value;

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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
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
