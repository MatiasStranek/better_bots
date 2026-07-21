import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileChessMoreSheet extends StatelessWidget {
  const MobileChessMoreSheet({
    super.key,
    required this.pgnText,
    required this.fenText,
    required this.onTrainingRestart,
    required this.isAnalysisMode,
    required this.onPastePgn,
    required this.onPasteFen,
    required this.isPlayFromHereActive,
    required this.onTogglePlayFromHere,
  });

  final String pgnText;
  final String fenText;
  final VoidCallback onTrainingRestart;
  final bool isAnalysisMode;
  final Future<bool> Function(String text) onPastePgn;
  final Future<bool> Function(String text) onPasteFen;
  final bool isPlayFromHereActive;
  final bool Function() onTogglePlayFromHere;

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

  Future<void> _pasteText({
    required BuildContext context,
    required Future<bool> Function(String text) onPaste,
    required String emptyMessage,
    required String successMessage,
    required String errorMessage,
  }) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim() ?? '';

    if (!context.mounted) {
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emptyMessage),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final loaded = await onPaste(text);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    if (loaded) {
      Navigator.of(context).pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(loaded ? successMessage : errorMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetBoard(BuildContext context) {
    Navigator.of(context).pop();
    onTrainingRestart();
  }

  void _togglePlayFromHere(BuildContext context) {
    final wasActive = isPlayFromHereActive;
    final isActive = onTogglePlayFromHere();
    final messenger = ScaffoldMessenger.of(context);
    final message = isActive
        ? 'Aktuelle Brettposition wurde für Play From Here markiert.'
        : wasActive
            ? 'Play From Here wurde deaktiviert.'
            : 'Aktuelle Brettposition konnte nicht markiert werden.';

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
              label: 'Neustart Zähler',
              isEnabled: !isAnalysisMode,
              foregroundColor: const Color(0xFFFF9800),
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
            _SheetAction(
              icon: Icons.content_paste,
              label: 'PASTE PGN',
              isEnabled: !isAnalysisMode,
              onTap: () => _pasteText(
                context: context,
                onPaste: onPastePgn,
                emptyMessage: 'Die Zwischenablage enthält keine PGN.',
                successMessage: 'PGN wurde eingefügt.',
                errorMessage: 'PGN konnte nicht eingefügt werden.',
              ),
            ),
            _SheetAction(
              icon: Icons.content_paste_go,
              label: 'PASTE FEN',
              isEnabled: !isAnalysisMode,
              onTap: () => _pasteText(
                context: context,
                onPaste: onPasteFen,
                emptyMessage: 'Die Zwischenablage enthält keine FEN.',
                successMessage: 'FEN wurde eingefügt.',
                errorMessage: 'FEN konnte nicht eingefügt werden.',
              ),
            ),
            _SheetAction(
              icon: Icons.person_pin_circle_outlined,
              label: 'PLAY FROM HERE',
              isEnabled: true,
              isActive: isPlayFromHereActive,
              onTap: () => _togglePlayFromHere(context),
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
    this.isActive = false,
    this.foregroundColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isActive;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = isActive
        ? const Color(0xFF55C878)
        : foregroundColor ?? Colors.white;
    final color = isEnabled ? baseColor : baseColor.withAlpha(70);

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
            if (isActive)
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFF55C878),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
