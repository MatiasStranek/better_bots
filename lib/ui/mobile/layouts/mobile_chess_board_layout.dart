import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/chess_board/mobile_chess_board_view.dart';

class MobileChessBoardLayout extends StatelessWidget {
  const MobileChessBoardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final availableHeight = constraints.maxHeight - 32;
        final boardSize = math.min(availableWidth, availableHeight);

        return Center(
          child: SizedBox.square(
            dimension: boardSize,
            child: const MobileChessBoardView(),
          ),
        );
      },
    );
  }
}
