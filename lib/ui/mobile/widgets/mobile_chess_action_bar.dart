import 'package:flutter/material.dart';

import 'mobile_chess_more_sheet.dart';

class MobileChessActionBar extends StatelessWidget {
  const MobileChessActionBar({
    super.key,
    required this.pgnText,
    required this.fenText,
    required this.onRestart,
    required this.onMenuPressed,
    required this.isSideMenuOpen,
    required this.isAnalysisMode,
    required this.canToggleAnalysisMode,
    required this.canNavigateAnalysisBack,
    required this.canNavigateAnalysisForward,
    required this.onToggleAnalysisMode,
    required this.onAnalysisBack,
    required this.onAnalysisForward,
    required this.onAnalysisBackToStart,
    required this.onAnalysisForwardToEnd,
    this.height = 64,
  });

  final String pgnText;
  final String fenText;
  final VoidCallback onRestart;
  final VoidCallback onMenuPressed;
  final bool isSideMenuOpen;
  final bool isAnalysisMode;
  final bool canToggleAnalysisMode;
  final bool canNavigateAnalysisBack;
  final bool canNavigateAnalysisForward;
  final VoidCallback onToggleAnalysisMode;
  final Future<void> Function() onAnalysisBack;
  final Future<void> Function() onAnalysisForward;
  final Future<void> Function() onAnalysisBackToStart;
  final Future<void> Function() onAnalysisForwardToEnd;
  final double height;

  Future<void> _showMoreSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      builder: (context) {
        return MobileChessMoreSheet(
          pgnText: pgnText,
          fenText: fenText,
          onRestart: onRestart,
          isAnalysisMode: isAnalysisMode,
          canToggleAnalysisMode: canToggleAnalysisMode,
          onToggleAnalysisMode: onToggleAnalysisMode,
        );
      },
    );
  }

  void _goAnalysisBack() {
    onAnalysisBack();
  }

  void _goAnalysisForward() {
    onAnalysisForward();
  }

  void _goAnalysisBackToStart() {
    onAnalysisBackToStart();
  }

  void _goAnalysisForwardToEnd() {
    onAnalysisForwardToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(28), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionBarButton(
              icon: isSideMenuOpen ? Icons.keyboard_arrow_left : Icons.menu,
              tooltip: isSideMenuOpen ? 'Menü schließen' : 'Menü öffnen',
              isEnabled: true,
              onPressed: onMenuPressed,
            ),
          ),
          const Expanded(
            child: _ActionBarButton(
              icon: Icons.sync,
              tooltip: 'Brett drehen kommt bald',
              isEnabled: false,
            ),
          ),
          Expanded(
            child: _ActionBarButton(
              icon: Icons.keyboard_double_arrow_left,
              tooltip: 'Analyse zurück',
              isEnabled: isAnalysisMode && canNavigateAnalysisBack,
              onPressed: _goAnalysisBack,
              onLongPress: _goAnalysisBackToStart,
            ),
          ),
          Expanded(
            child: _ActionBarButton(
              icon: Icons.keyboard_double_arrow_right,
              tooltip: 'Analyse vor',
              isEnabled: isAnalysisMode && canNavigateAnalysisForward,
              onPressed: _goAnalysisForward,
              onLongPress: _goAnalysisForwardToEnd,
            ),
          ),
          Expanded(
            child: _ActionBarButton(
              icon: Icons.more_horiz,
              tooltip: 'Weitere Aktionen',
              isEnabled: true,
              onPressed: () => _showMoreSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBarButton extends StatelessWidget {
  const _ActionBarButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    this.onPressed,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  static const Color _activeColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? _activeColor : Colors.white.withAlpha(76);

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: isEnabled ? onPressed : null,
        onLongPress: isEnabled ? onLongPress : null,
        radius: 28,
        child: Center(
          child: Icon(icon, size: 32, color: color),
        ),
      ),
    );
  }
}
