import 'package:chess/chess.dart' as chess;

String pieceAsset(chess.Piece piece) {
  final colorPrefix = piece.color == chess.Color.WHITE ? 'w' : 'b';
  final pieceLetter = piece.type.toUpperCase();

  return 'assets/pieces/$colorPrefix$pieceLetter.svg';
}
