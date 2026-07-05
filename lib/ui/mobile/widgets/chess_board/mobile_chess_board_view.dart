import 'package:flutter/material.dart';

import 'mobile_chess_board_square.dart';

class MobileChessBoardView extends StatelessWidget {
  const MobileChessBoardView({super.key});

  static const List<String?> _startingPosition = [
    'bR',
    'bN',
    'bB',
    'bQ',
    'bK',
    'bB',
    'bN',
    'bR',
    'bP',
    'bP',
    'bP',
    'bP',
    'bP',
    'bP',
    'bP',
    'bP',
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    'wP',
    'wP',
    'wP',
    'wP',
    'wP',
    'wP',
    'wP',
    'wP',
    'wR',
    'wN',
    'wB',
    'wQ',
    'wK',
    'wB',
    'wN',
    'wR',
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/board/maple.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final column = index % 8;
              final isLightSquare = (row + column).isEven;

              return MobileChessBoardSquare(
                isLightSquare: isLightSquare,
                pieceCode: _startingPosition[index],
              );
            },
          ),
        ),
      ),
    );
  }
}
