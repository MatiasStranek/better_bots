import 'package:flutter/material.dart';

class MobileChessBottomView extends StatelessWidget {
  const MobileChessBottomView({
    super.key,
    required this.statusText,
    required this.playerSideText,
    required this.pgnText,
  });

  final String statusText;
  final String playerSideText;
  final String pgnText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BottomInfoLine(label: 'Status', value: statusText, isPrimary: true),
          const SizedBox(height: 6),
          _BottomInfoLine(label: 'Seite', value: playerSideText),
          const SizedBox(height: 6),
          _BottomInfoLine(label: 'PGN', value: pgnText),
        ],
      ),
    );
  }
}

class _BottomInfoLine extends StatelessWidget {
  const _BottomInfoLine({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.52),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    final valueStyle = TextStyle(
      color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.78),
      fontSize: isPrimary ? 14 : 12,
      fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
    );

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
