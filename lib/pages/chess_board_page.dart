import 'package:flutter/material.dart';

import '../widgets/chess_board_widget.dart';

class ChessBoardPage extends StatelessWidget {
  const ChessBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Better Bots')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ChessBoardWidget(),
      ),
    );
  }
}
