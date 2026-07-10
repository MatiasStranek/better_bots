import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/better_bots_database.dart';
import 'pages/chess_board_page.dart';
import 'ui/mobile/pages/mobile_chess_board_page.dart';
import 'utils/debug_crash_reporter.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final crashReporter = DebugCrashReporter.instance;
      crashReporter.recordMessage('main() gestartet.');

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        crashReporter.recordFlutterError(details);
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        crashReporter.recordError(
          error,
          stack,
          context: 'PlatformDispatcher',
        );
        return true;
      };

      try {
        await BetterBotsDatabase.instance.init();

        // Nur die Android-Navigationsleiste anzeigen,
        // Statusleiste ausgeblendet lassen.
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [SystemUiOverlay.bottom],
        );

        runApp(const BetterBotsApp());
      } catch (error, stackTrace) {
        crashReporter.recordError(
          error,
          stackTrace,
          context: 'App-Start',
        );

        runApp(
          DebugStartFailureApp(
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    },
    (Object error, StackTrace stackTrace) {
      DebugCrashReporter.instance.recordError(
        error,
        stackTrace,
        context: 'runZonedGuarded',
      );
    },
  );
}

class BetterBotsApp extends StatelessWidget {
  const BetterBotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Better Bots',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const AppHomeRouter(),
    );
  }
}

class AppHomeRouter extends StatelessWidget {
  const AppHomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    if (isMobilePlatform) {
      return const MobileChessBoardPage();
    }

    return const ChessBoardPage();
  }
}

class DebugStartFailureApp extends StatelessWidget {
  const DebugStartFailureApp({
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
                  'Öffne bei einem harten Android-Absturz die separate '
                  'App-Verknüpfung „Better Bots Crash Log“ und kopiere dort '
                  'den nativen Log.',
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
