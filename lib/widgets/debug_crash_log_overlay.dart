import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/debug_crash_reporter.dart';

class DebugCrashLogOverlay extends StatelessWidget {
  const DebugCrashLogOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        const Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: _DebugCrashButton(),
          ),
        ),
      ],
    );
  }
}

class _DebugCrashButton extends StatelessWidget {
  const _DebugCrashButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withAlpha(220),
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showCrashLogSheet(context),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  Future<void> _showCrashLogSheet(BuildContext context) async {
    final report = await DebugCrashReporter.instance.buildReport();

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101014),
      builder: (sheetContext) {
        return _CrashLogSheet(initialReport: report);
      },
    );
  }
}

class _CrashLogSheet extends StatefulWidget {
  const _CrashLogSheet({
    required this.initialReport,
  });

  final String initialReport;

  @override
  State<_CrashLogSheet> createState() => _CrashLogSheetState();
}

class _CrashLogSheetState extends State<_CrashLogSheet> {
  late String _report = widget.initialReport;
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });

    final report = await DebugCrashReporter.instance.buildReport();

    if (!mounted) {
      return;
    }

    setState(() {
      _report = report;
      _isRefreshing = false;
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _report));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crash-Log wurde kopiert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clear() async {
    await DebugCrashReporter.instance.clearNativeLog();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Icon(Icons.bug_report, color: Colors.white),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Debug Crash-Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isRefreshing ? null : _refresh,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Aktualisieren',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Schließen',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(28)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _report,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Crash-Log kopieren'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Leeren'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(80)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DebugCrashFallbackApp extends StatelessWidget {
  const DebugCrashFallbackApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Better Bots Startfehler',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      builder: (context, child) {
        return DebugCrashLogOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        backgroundColor: const Color(0xFF101014),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Better Bots konnte nicht starten',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tippe oben rechts auf den roten Käfer-Button und kopiere '
                  'den Crash-Log.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '$error\n\n$stackTrace',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
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
