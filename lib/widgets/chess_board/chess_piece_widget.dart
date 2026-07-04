import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/piece_asset_utils.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    required this.piece,
    required this.square,
    required this.canDrag,
    required this.onDragStarted,
    required this.onDragEnded,
    super.key,
  });

  final chess.Piece piece;
  final String square;
  final bool canDrag;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    final assetPath = pieceAsset(piece);

    final pieceImage = Padding(
      padding: const EdgeInsets.all(6),
      child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
    );

    if (!canDrag) {
      return pieceImage;
    }

    return Draggable<String>(
      data: square,
      feedback: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.transparent,
          child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: pieceImage),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded(),
      child: pieceImage,
    );
  }
}
