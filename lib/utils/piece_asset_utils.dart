import 'package:chess/chess.dart' as chess;

String pieceAsset(chess.Piece piece) {
  return pieceAssetFromCode(chessPieceCode(piece));
}

String pieceAssetFromCode(String pieceCode) {
  return 'assets/pieces/$pieceCode.svg';
}

String chessPieceCode(chess.Piece piece) {
  final colorPrefix = piece.color == chess.Color.WHITE ? 'w' : 'b';
  return '$colorPrefix${chessPieceLetter(piece)}';
}

String chessPieceLetter(chess.Piece piece) {
  final typeText = piece.type.toString().toLowerCase();

  if (typeText == 'p' ||
      typeText.endsWith('.p') ||
      typeText.contains('pawn')) {
    return 'P';
  }

  if (typeText == 'n' ||
      typeText.endsWith('.n') ||
      typeText.contains('knight')) {
    return 'N';
  }

  if (typeText == 'b' ||
      typeText.endsWith('.b') ||
      typeText.contains('bishop')) {
    return 'B';
  }

  if (typeText == 'r' ||
      typeText.endsWith('.r') ||
      typeText.contains('rook')) {
    return 'R';
  }

  if (typeText == 'q' ||
      typeText.endsWith('.q') ||
      typeText.contains('queen')) {
    return 'Q';
  }

  if (typeText == 'k' ||
      typeText.endsWith('.k') ||
      typeText.contains('king')) {
    return 'K';
  }

  return 'P';
}

/// Liest den Figurencode direkt aus der FEN.
///
/// Das ist für Windows/Desktop wichtig, weil der Debug-Screenshot gezeigt hat:
/// FEN und PGN enthalten bereits die promovierte Figur, während das Widget noch
/// einen Bauern zeichnet. Die FEN ist hier die autoritative Quelle für die
/// sichtbare Brettstellung.
String? pieceCodeFromFenAtSquare({
  required String fen,
  required String square,
}) {
  if (square.length != 2) {
    return null;
  }

  final fileIndex = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.tryParse(square.substring(1, 2));

  if (fileIndex < 0 || fileIndex > 7 || rank == null || rank < 1 || rank > 8) {
    return null;
  }

  final parts = fen.trim().split(RegExp(r'\s+'));

  if (parts.isEmpty || parts.first.isEmpty) {
    return null;
  }

  final boardPart = parts.first;
  final targetRow = 8 - rank;
  var row = 0;
  var col = 0;

  for (final rune in boardPart.runes) {
    final char = String.fromCharCode(rune);

    if (char == '/') {
      row += 1;
      col = 0;
      continue;
    }

    final emptyCount = int.tryParse(char);

    if (emptyCount != null) {
      col += emptyCount;
      continue;
    }

    if (row == targetRow && col == fileIndex) {
      return _pieceCodeFromFenChar(char);
    }

    col += 1;
  }

  return null;
}

String? _pieceCodeFromFenChar(String fenChar) {
  if (fenChar.length != 1) {
    return null;
  }

  final pieceLetter = fenChar.toUpperCase();

  if (pieceLetter != 'P' &&
      pieceLetter != 'N' &&
      pieceLetter != 'B' &&
      pieceLetter != 'R' &&
      pieceLetter != 'Q' &&
      pieceLetter != 'K') {
    return null;
  }

  final colorPrefix = fenChar == pieceLetter ? 'w' : 'b';

  return '$colorPrefix$pieceLetter';
}
