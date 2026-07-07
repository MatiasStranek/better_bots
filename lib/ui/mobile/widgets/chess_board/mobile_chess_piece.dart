import 'package:flutter/material.dart';

import '../../../../widgets/chess_board/chess_piece_visual.dart';

class MobileChessPiece extends StatelessWidget {
  const MobileChessPiece({super.key, required this.pieceCode});

  final String pieceCode;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/pieces/$pieceCode.svg';

    return ChessPieceVisual(
      assetPath: assetPath,
      keyValue: 'mobile-$pieceCode-$assetPath',
    );
  }
}
