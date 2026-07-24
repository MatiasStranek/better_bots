import 'package:flutter/material.dart';

import '../widgets/chess_board_widget.dart';

class ChessBoardPage extends StatelessWidget {
  const ChessBoardPage({super.key});

  static const String _backgroundAssetPath =
      'assets/background/background.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: ChessBoardWidget(),
          ),
          const Positioned(
            left: 18,
            top: 16,
            child: IgnorePointer(
              child: Text(
                'Better Bots',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
