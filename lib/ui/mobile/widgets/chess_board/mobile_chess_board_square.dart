import 'package:flutter/material.dart';

import 'mobile_chess_piece.dart';

class MobileChessBoardSquare extends StatelessWidget {
  const MobileChessBoardSquare({
    super.key,
    required this.isLightSquare,
    required this.pieceCode,
  });

  final bool isLightSquare;
  final String? pieceCode;

  @override
  Widget build(BuildContext context) {
    final squareColor = isLightSquare
        ? const Color(0x99F0D9B5)
        : const Color(0x99946F51);

    return ColoredBox(
      color: squareColor,
      child: pieceCode == null
          ? const SizedBox.expand()
          : MobileChessPiece(pieceCode: pieceCode!),
    );
  }
}
