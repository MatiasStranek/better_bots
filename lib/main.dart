import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/chess_board_page.dart';
import 'ui/mobile/pages/mobile_chess_board_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nur die Android-Navigationsleiste anzeigen,
  // Statusleiste ausgeblendet lassen.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.bottom],
  );

  runApp(const BetterBotsApp());
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
