const List<String> chessFiles = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

String squareNameFromIndex({required int index, required bool playerIsWhite}) {
  final row = index ~/ 8;
  final col = index % 8;

  if (playerIsWhite) {
    final file = chessFiles[col];
    final rank = 8 - row;
    return '$file$rank';
  }

  final file = chessFiles[7 - col];
  final rank = row + 1;
  return '$file$rank';
}

bool isLightSquareFromIndex(int index) {
  final row = index ~/ 8;
  final col = index % 8;

  return (row + col).isEven;
}
