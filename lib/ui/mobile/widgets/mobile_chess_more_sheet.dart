import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileChessMoreSheet extends StatelessWidget {
  const MobileChessMoreSheet({
    super.key,
    required this.pgnText,
    required this.fenText,
    required this.onRestart,
    required this.canToggleAnalysisMode,
    required this.onToggleAnalysisMode,
  });

  final String pgnText;
  final String fenText;
  final VoidCallback onRestart;
  final bool canToggleAnalysisMode;
  final VoidCallback onToggleAnalysisMode;

  bool get _hasPgn {
    return pgnText.trim().isNotEmpty && pgnText.trim() != '-';
  }

  bool get _hasFen {
    return fenText.trim().isNotEmpty && fenText.trim() != '-';
  }

  Future<void> _copyText({
    required BuildContext context,
    required String text,
    required String emptyMessage,
    required String successMessage,
  }) async {
    if (text.trim().isEmpty || text.trim() == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emptyMessage),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(successMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetBoard(BuildContext context) {
    Navigator.of(context).pop();
    onRestart();
  }

  void _toggleAnalysis(BuildContext context) {
    Navigator.of(context).pop();
    onToggleAnalysisMode();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 8, 18, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  size: 30,
                  color: Color(0xFF5C9DFF),
                ),
              ),
            ),
            _SheetAction(
              icon: Icons.refresh,
              label: 'RESET BOARD',
              onTap: () => _resetBoard(context),
            ),
            _SheetAction(
              icon: Icons.copy,
              label: 'PGN KOPIEREN',
              isEnabled: _hasPgn,
              onTap: () => _copyText(
                context: context,
                text: pgnText,
                emptyMessage: 'Noch keine PGN vorhanden.',
                successMessage: 'PGN wurde kopiert.',
              ),
            ),
            _SheetAction(
              icon: Icons.copy,
              label: 'FEN KOPIEREN',
              isEnabled: _hasFen,
              onTap: () => _copyText(
                context: context,
                text: fenText,
                emptyMessage: 'Keine FEN vorhanden.',
                successMessage: 'FEN wurde kopiert.',
              ),
            ),
            const _SheetAction(
              icon: Icons.save,
              label: 'SAVE CURRENT PGN',
              isEnabled: false,
            ),
            _SheetAction(
              icon: Icons.analytics_outlined,
              label: 'ANALYZE CURRENT PGN',
              isEnabled: canToggleAnalysisMode,
              onTap: () => _toggleAnalysis(context),
            ),
            const _SheetAction(
              icon: Icons.person,
              label: 'PLAY FROM HERE',
              isEnabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    this.isEnabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? Colors.white : Colors.white.withAlpha(70);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
