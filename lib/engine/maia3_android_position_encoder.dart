import 'package:chess/chess.dart' as chess;

class Maia3AndroidEncodedPosition {
  const Maia3AndroidEncodedPosition({
    required this.tokens,
    required this.legalMoveIndices,
    required this.legalMoveUcis,
  });

  final List<double> tokens;
  final List<int> legalMoveIndices;
  final List<String> legalMoveUcis;
}

class Maia3AndroidPositionEncoder {
  const Maia3AndroidPositionEncoder();

  static const String defaultStartFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static const int historyLength = 8;
  static const int squares = 64;
  static const int pieceChannels = 12;
  static const int tokenWidth = pieceChannels * historyLength + 1;

  Maia3AndroidEncodedPosition encode({
    required String startFen,
    required List<String> moves,
    required String fen,
  }) {
    final game = chess.Chess();
    final normalizedStartFen = _normalizeFen(startFen);

    var loaded = false;

    try {
      loaded = game.load(normalizedStartFen);
    } catch (_) {
      loaded = false;
    }

    if (!loaded) {
      game.reset();
    }

    final boardHistory = <List<double>>[
      _tokenizeBoard(game),
    ];

    var replayFailed = false;

    for (final moveUci in moves) {
      if (!_applyUciMove(game, moveUci)) {
        replayFailed = true;
        break;
      }

      boardHistory.add(_tokenizeBoard(game));
    }

    if (replayFailed) {
      final currentFen = _normalizeFen(fen);

      try {
        if (game.load(currentFen)) {
          boardHistory
            ..clear()
            ..add(_tokenizeBoard(game));
        }
      } catch (_) {
        // Der beste Fallback ist die bis dahin geladene Position.
      }
    }

    final legalMoves = _legalMoveUcis(game);
    final blackToMove = game.turn == chess.Color.BLACK;

    final legalMoveIndices = <int>[];
    final legalMoveUcis = <String>[];

    for (final uci in legalMoves) {
      final maiaUci = blackToMove ? _mirrorMove(uci) : uci;
      final index = _maiaMoveIndex(maiaUci);

      if (index == null || index < 0 || index >= 4352) {
        continue;
      }

      legalMoveIndices.add(index);
      legalMoveUcis.add(uci);
    }

    if (legalMoveIndices.isEmpty) {
      throw StateError(
        'Keine legalen Maia-Züge kodierbar. FEN: ${game.fen}',
      );
    }

    return Maia3AndroidEncodedPosition(
      tokens: _buildHistoricalTokens(boardHistory),
      legalMoveIndices: legalMoveIndices,
      legalMoveUcis: legalMoveUcis,
    );
  }

  String _normalizeFen(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty || trimmed == 'startpos') {
      return defaultStartFen;
    }

    return trimmed;
  }

  bool _applyUciMove(chess.Chess game, String uciMove) {
    final trimmed = uciMove.trim();

    if (trimmed.length < 4 || trimmed == '(none)') {
      return false;
    }

    final moveData = <String, String>{
      'from': trimmed.substring(0, 2),
      'to': trimmed.substring(2, 4),
    };

    if (trimmed.length >= 5) {
      moveData['promotion'] = trimmed.substring(4, 5).toLowerCase();
    }

    try {
      final moved = game.move(moveData);

      return moved != null && moved != false;
    } catch (_) {
      return false;
    }
  }

  List<String> _legalMoveUcis(chess.Chess game) {
    final rawMoves = game.moves(<String, Object?>{
      'verbose': true,
    });

    final ucis = <String>[];

    for (final rawMove in rawMoves) {
      final from = _readMoveFrom(rawMove);
      final to = _readMoveTo(rawMove);

      if (from == null || to == null) {
        continue;
      }

      final promotion = _readMovePromotion(rawMove);
      ucis.add('$from$to$promotion');
    }

    return ucis;
  }

  String? _readMoveFrom(dynamic move) {
    if (move is Map) {
      return _squareFromAny(move['from']);
    }

    try {
      return _squareFromAny(move.fromAlgebraic);
    } catch (_) {
      // Weiter unten andere Feldnamen probieren.
    }

    try {
      return _squareFromAny(move.from);
    } catch (_) {
      // Weiter unten andere Feldnamen probieren.
    }

    try {
      return _squareFromAny(move.source);
    } catch (_) {
      return null;
    }
  }

  String? _readMoveTo(dynamic move) {
    if (move is Map) {
      return _squareFromAny(move['to']);
    }

    try {
      return _squareFromAny(move.toAlgebraic);
    } catch (_) {
      // Weiter unten andere Feldnamen probieren.
    }

    try {
      return _squareFromAny(move.to);
    } catch (_) {
      // Weiter unten andere Feldnamen probieren.
    }

    try {
      return _squareFromAny(move.target);
    } catch (_) {
      return null;
    }
  }

  String _readMovePromotion(dynamic move) {
    dynamic value;

    if (move is Map) {
      value = move['promotion'];
    } else {
      try {
        value = move.promotion;
      } catch (_) {
        value = null;
      }
    }

    return _normalizePromotion(value);
  }

  String? _squareFromAny(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return _squareNameFromIndex(value);
    }

    final text = value.toString().toLowerCase();
    final match = RegExp(r'[a-h][1-8]').firstMatch(text);

    return match?.group(0);
  }

  String _squareNameFromIndex(int index) {
    final bounded = index.clamp(0, 63).toInt();
    final file = bounded % 8;
    final rank = bounded ~/ 8;

    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }

  String _normalizePromotion(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().toLowerCase();

    if (text == 'q' || text.endsWith('.q') || text.contains('queen')) {
      return 'q';
    }

    if (text == 'r' || text.endsWith('.r') || text.contains('rook')) {
      return 'r';
    }

    if (text == 'b' || text.endsWith('.b') || text.contains('bishop')) {
      return 'b';
    }

    if (text == 'n' || text.endsWith('.n') || text.contains('knight')) {
      return 'n';
    }

    return '';
  }

  List<double> _buildHistoricalTokens(List<List<double>> boardHistory) {
    final trimmedHistory = boardHistory.length <= historyLength
        ? List<List<double>>.of(boardHistory)
        : boardHistory.sublist(boardHistory.length - historyLength);

    final paddedHistory = <List<double>>[];

    while (paddedHistory.length + trimmedHistory.length < historyLength) {
      paddedHistory.add(trimmedHistory.first);
    }

    paddedHistory.addAll(trimmedHistory);

    final tokens = <double>[];

    for (var square = 0; square < squares; square++) {
      for (final boardTokens in paddedHistory) {
        final offset = square * pieceChannels;

        for (var channel = 0; channel < pieceChannels; channel++) {
          tokens.add(boardTokens[offset + channel]);
        }
      }

      // Maia3-5m wurde ohne echte Time-Info exportiert.
      // Der letzte Kanal ist clk_ponder / 100 und bleibt hier 0.
      tokens.add(0.0);
    }

    return tokens;
  }

  List<double> _tokenizeBoard(chess.Chess game) {
    final tokens = List<double>.filled(squares * pieceChannels, 0.0);
    final blackToMove = game.turn == chess.Color.BLACK;

    for (var squareIndex = 0; squareIndex < squares; squareIndex++) {
      final square = _squareNameFromIndex(squareIndex);
      final piece = game.get(square);

      if (piece == null) {
        continue;
      }

      final targetSquareIndex = blackToMove
          ? _squareIndex(_mirrorSquare(square))
          : squareIndex;

      final color = blackToMove ? _oppositeColor(piece.color) : piece.color;
      final pieceOffset = _pieceTokenOffset(piece);

      if (pieceOffset == null) {
        continue;
      }

      final colorOffset = color == chess.Color.WHITE ? 0 : 6;
      tokens[targetSquareIndex * pieceChannels + colorOffset + pieceOffset] =
          1.0;
    }

    return tokens;
  }

  chess.Color _oppositeColor(chess.Color color) {
    return color == chess.Color.WHITE ? chess.Color.BLACK : chess.Color.WHITE;
  }

  int? _pieceTokenOffset(chess.Piece piece) {
    final typeText = piece.type.toString().toLowerCase();

    if (typeText == 'p' ||
        typeText.endsWith('.p') ||
        typeText.contains('pawn')) {
      return 0;
    }

    if (typeText == 'n' ||
        typeText.endsWith('.n') ||
        typeText.contains('knight')) {
      return 1;
    }

    if (typeText == 'b' ||
        typeText.endsWith('.b') ||
        typeText.contains('bishop')) {
      return 2;
    }

    if (typeText == 'r' ||
        typeText.endsWith('.r') ||
        typeText.contains('rook')) {
      return 3;
    }

    if (typeText == 'q' ||
        typeText.endsWith('.q') ||
        typeText.contains('queen')) {
      return 4;
    }

    if (typeText == 'k' ||
        typeText.endsWith('.k') ||
        typeText.contains('king')) {
      return 5;
    }

    return null;
  }

  int? _maiaMoveIndex(String maiaUci) {
    if (maiaUci.length < 4) {
      return null;
    }

    final from = maiaUci.substring(0, 2);
    final to = maiaUci.substring(2, 4);

    if (maiaUci.length >= 5) {
      final promotion = maiaUci.substring(4, 5).toLowerCase();
      final promotionIndex = switch (promotion) {
        'q' => 0,
        'r' => 1,
        'b' => 2,
        'n' => 3,
        _ => null,
      };

      if (promotionIndex == null) {
        return null;
      }

      final fromFile = _fileIndex(from);
      final toFile = _fileIndex(to);

      if (fromFile == null || toFile == null) {
        return null;
      }

      return 4096 + ((fromFile * 8 + toFile) * 4) + promotionIndex;
    }

    final fromIndex = _squareIndex(from);
    final toIndex = _squareIndex(to);

    return fromIndex * 64 + toIndex;
  }

  int _squareIndex(String square) {
    final file = _fileIndex(square) ?? 0;
    final rank = int.tryParse(square.substring(1, 2)) ?? 1;

    return (rank - 1) * 8 + file;
  }

  int? _fileIndex(String square) {
    if (square.isEmpty) {
      return null;
    }

    final fileCode = square.codeUnitAt(0);
    final file = fileCode - 'a'.codeUnitAt(0);

    if (file < 0 || file > 7) {
      return null;
    }

    return file;
  }

  String _mirrorSquare(String square) {
    final file = square.substring(0, 1);
    final rank = int.tryParse(square.substring(1, 2)) ?? 1;

    return '$file${9 - rank}';
  }

  String _mirrorMove(String uci) {
    final promotion = uci.length >= 5 ? uci.substring(4) : '';

    return '${_mirrorSquare(uci.substring(0, 2))}'
        '${_mirrorSquare(uci.substring(2, 4))}'
        '$promotion';
  }
}
