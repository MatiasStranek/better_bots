import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DebugCrashReporter {
  DebugCrashReporter._();

  static final DebugCrashReporter instance = DebugCrashReporter._();

  static const MethodChannel _nativeChannel =
      MethodChannel('better_bots/debugCrashLog');

  final List<String> _entries = <String>[];

  void recordMessage(String message) {
    _add('INFO', message);
  }

  void recordFlutterError(FlutterErrorDetails details) {
    final buffer = StringBuffer()
      ..writeln(details.exceptionAsString());

    if (details.library != null) {
      buffer.writeln('library: ${details.library}');
    }

    if (details.context != null) {
      buffer.writeln('context: ${details.context}');
    }

    if (details.stack != null) {
      buffer.writeln(details.stack);
    }

    _add('FLUTTER_ERROR', buffer.toString());
  }

  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String context = 'Dart',
  }) {
    final buffer = StringBuffer()
      ..writeln(error);

    if (stackTrace != null) {
      buffer.writeln(stackTrace);
    }

    _add(context, buffer.toString());
  }

  Future<String> buildReport() async {
    final buffer = StringBuffer()
      ..writeln('Better Bots Debug Crash Report')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('')
      ..writeln('Dart / Flutter')
      ..writeln('------------------------------');

    if (_entries.isEmpty) {
      buffer.writeln('Keine Dart-Fehler im aktuellen Prozess gespeichert.');
    } else {
      for (final entry in _entries) {
        buffer.writeln(entry);
        buffer.writeln('');
      }
    }

    buffer
      ..writeln('')
      ..writeln('Android Native')
      ..writeln('------------------------------');

    try {
      final result = await _nativeChannel.invokeMethod<Map<dynamic, dynamic>>(
        'debugCrashLogGet',
      );

      final nativeLog = result?['log']?.toString().trim() ?? '';
      final nativeInfo = result?['info']?.toString().trim() ?? '';

      if (nativeInfo.isNotEmpty) {
        buffer.writeln(nativeInfo);
        buffer.writeln('');
      }

      if (nativeLog.isEmpty) {
        buffer.writeln('Kein nativer Crash-Log gespeichert.');
      } else {
        buffer.writeln(nativeLog);
      }
    } catch (error, stackTrace) {
      buffer
        ..writeln('Native Crash-Log-Abfrage fehlgeschlagen:')
        ..writeln(error)
        ..writeln(stackTrace);
    }

    return buffer.toString();
  }

  Future<void> clearNativeLog() async {
    try {
      await _nativeChannel.invokeMethod<void>('debugCrashLogClear');
    } catch (_) {
      // Debug-Hilfe darf die App nie selbst crashen.
    }
  }

  void _add(String type, String message) {
    final entry = StringBuffer()
      ..writeln('[${DateTime.now().toIso8601String()}] $type')
      ..writeln(message.trimRight());

    _entries.add(entry.toString());

    if (_entries.length > 50) {
      _entries.removeAt(0);
    }
  }
}
