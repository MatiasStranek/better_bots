import 'package:flutter/material.dart';

class MobileChessAnalysisButton extends StatelessWidget {
  const MobileChessAnalysisButton({
    super.key,
    required this.isAnalysisMode,
    required this.isEnabled,
    required this.onPressed,
    this.size = 52,
  });

  final bool isAnalysisMode;
  final bool isEnabled;
  final VoidCallback onPressed;
  final double size;

  static const Color _activeColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isEnabled ? Colors.white : Colors.white.withAlpha(80);
    final backgroundColor = isAnalysisMode
        ? _activeColor
        : isEnabled
            ? const Color(0xFF151515)
            : const Color(0xFF151515).withAlpha(170);

    return Tooltip(
      message: isAnalysisMode ? 'Analyse beenden' : 'Analyse starten',
      child: Material(
        color: backgroundColor,
        elevation: isAnalysisMode ? 6 : 2,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: isEnabled ? onPressed : null,
          radius: size / 2,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.analytics_outlined,
              size: 30,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
