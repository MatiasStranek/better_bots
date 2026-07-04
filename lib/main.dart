import 'package:flutter/material.dart';

import 'pages/chess_board_page.dart';

void main() {
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
      home: const ChessBoardPage(),
    );
  }
}
