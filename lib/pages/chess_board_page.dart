import 'package:flutter/material.dart';

import '../widgets/chess_board_widget.dart';

class ChessBoardPage extends StatelessWidget {
  const ChessBoardPage({super.key});

  static const String _backgroundAssetPath =
      'assets/background/background.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Better Bots')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(38),
            ),
          ),
          const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ChessBoardWidget(),
          ),
        ],
      ),
    );
  }
}
