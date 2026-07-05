import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileChessCopyPgnButton extends StatelessWidget {
  const MobileChessCopyPgnButton({super.key, required this.pgnText});

  final String pgnText;

  bool get _hasPgn {
    return pgnText.trim().isNotEmpty && pgnText.trim() != '-';
  }

  Future<void> _copyPgn(BuildContext context) async {
    if (!_hasPgn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Noch keine PGN vorhanden.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: pgnText));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PGN wurde kopiert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _copyPgn(context),
        icon: const Icon(Icons.copy, size: 18),
        label: const Text('PGN kopieren'),
      ),
    );
  }
}
