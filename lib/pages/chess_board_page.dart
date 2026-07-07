import 'package:flutter/material.dart';

import '../widgets/chess_board_widget.dart';

class ChessBoardPage extends StatelessWidget {
  const ChessBoardPage({super.key});

  static const String _backgroundAssetPath =
      'assets/background/background.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Better Bots'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 16),
            child: ChessBoardWidget(),
          ),
        ],
      ),
    );
  }
}
