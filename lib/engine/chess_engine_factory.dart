import 'package:flutter/foundation.dart';

import 'chess_engine.dart';
import 'maia3_android_method_channel_engine.dart';
import 'maia3_windows_uci_engine.dart';
import 'noop_chess_engine.dart';
import 'stockfish_plugin_engine.dart';
import 'stockfish_windows_engine.dart';

class ChessEngineFactory {
  const ChessEngineFactory._();

  static ChessEngine createDefaultEngine() {
    if (kIsWeb) {
      return NoopChessEngine();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return StockfishPluginEngine();

      case TargetPlatform.windows:
        return StockfishWindowsEngine();

      case TargetPlatform.linux:
        return NoopChessEngine();

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
        return NoopChessEngine();
    }
  }


  static ChessEngine createBotProfileEngine() {
    if (kIsWeb) {
      return NoopChessEngine();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return Maia3WindowsUciEngine();

      case TargetPlatform.android:
        return Maia3AndroidMethodChannelEngine();

      case TargetPlatform.linux:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
        return NoopChessEngine();
    }
  }

  static ChessEngine createMobileEngine() {
    return createDefaultEngine();
  }
}

