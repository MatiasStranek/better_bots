import 'package:chess/chess.dart' as chess;

import 'board_move.dart';
import 'engine_analysis_line.dart';

class AnalysisSession {
  AnalysisSession({required this.startFen}) : analysisGame = chess.Chess() {
    final loaded = analysisGame.load(startFen);

    if (!loaded) {
      throw ArgumentError.value(startFen, 'startFen', 'Ungültige Analyse-FEN');
    }
  }

  /// Original-FEN der Partie an dem Moment, in dem Analyse aktiviert wurde.
  final String startFen;

  /// Komplett getrenntes Analysebrett. Dieses Objekt darf nie in _game kopiert
  /// werden und _game darf nie aus diesem Objekt ersetzt werden.
  final chess.Chess analysisGame;

  final List<BoardMove> _analysisMoves = [];

  int currentPly = 0;

  List<EngineAnalysisLine> topLines = const [];

  bool isAnalyzing = false;

  String statusText = 'Analysemodus aktiv.';

  List<BoardMove> get analysisMoves {
    return List.unmodifiable(_analysisMoves);
  }

  bool get canStepBack {
    return currentPly > 0;
  }

  bool get canStepForward {
    return currentPly < _analysisMoves.length;
  }

  String get fen {
    return analysisGame.fen;
  }

  String get pgn {
    final currentPgn = analysisGame.pgn();
    return currentPgn.isEmpty ? '-' : currentPgn;
  }

  bool get isGameOver {
    return analysisGame.game_over ||
        analysisGame.in_checkmate ||
        analysisGame.in_stalemate ||
        analysisGame.in_draw;
  }

  String? get lastFrom {
    if (currentPly <= 0 || currentPly > _analysisMoves.length) {
      return null;
    }

    return _analysisMoves[currentPly - 1].from;
  }

  String? get lastTo {
    if (currentPly <= 0 || currentPly > _analysisMoves.length) {
      return null;
    }

    return _analysisMoves[currentPly - 1].to;
  }

  String get sideToMoveText {
    return analysisGame.turn == chess.Color.WHITE ? 'Weiß' : 'Schwarz';
  }

  chess.Piece? pieceAt(String square) {
    return analysisGame.get(square);
  }

  bool canSelectPiece(String square) {
    if (isGameOver) {
      return false;
    }

    final piece = pieceAt(square);

    if (piece == null) {
      return false;
    }

    return piece.color == analysisGame.turn;
  }

  bool canMoveTo({required String from, required String to}) {
    if (from == to || isGameOver) {
      return false;
    }

    return legalTargetsFromSquare(from).contains(to);
  }

  List<String> legalTargetsFromSquare(String fromSquare) {
    final moves = analysisGame.moves({
      'square': fromSquare,
      'verbose': true,
    });

    final targets = <String>[];

    for (final move in moves) {
      if (move is chess.Move) {
        targets.add(move.toAlgebraic);
      } else if (move is Map && move['to'] is String) {
        targets.add(move['to'] as String);
      }
    }

    return targets;
  }

  bool playMove({required String from, required String to, String? promotion}) {
    if (currentPly < _analysisMoves.length) {
      _analysisMoves.removeRange(currentPly, _analysisMoves.length);
    }

    final normalizedPromotion = promotion == null || promotion.isEmpty
        ? null
        : promotion.toLowerCase();

    final moveData = <String, String>{'from': from, 'to': to};

    if (normalizedPromotion != null && normalizedPromotion.isNotEmpty) {
      moveData['promotion'] = normalizedPromotion;
    }

    final moved = analysisGame.move(moveData);

    if (!moved) {
      return false;
    }

    _analysisMoves.add(
      BoardMove(from: from, to: to, promotion: normalizedPromotion),
    );
    currentPly = _analysisMoves.length;

    topLines = const [];
    statusText = 'Analysezug gespielt: $from$to${normalizedPromotion ?? ''}';

    return true;
  }

  bool stepBack() {
    if (!canStepBack) {
      return false;
    }

    currentPly -= 1;
    _rebuildCurrentPosition();
    topLines = const [];
    statusText = 'Analyse: einen Zug zurück.';

    return true;
  }

  bool stepForward() {
    if (!canStepForward) {
      return false;
    }

    currentPly += 1;
    _rebuildCurrentPosition();
    topLines = const [];
    statusText = 'Analyse: einen Zug vor.';

    return true;
  }

  void updateTopLines(List<EngineAnalysisLine> lines) {
    final sortedLines = List<EngineAnalysisLine>.from(lines)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    topLines = List.unmodifiable(sortedLines.take(5));
  }

  void clearTopLines() {
    topLines = const [];
  }

  void _rebuildCurrentPosition() {
    final loaded = analysisGame.load(startFen);

    if (!loaded) {
      throw StateError('Analyse-Start-FEN konnte nicht erneut geladen werden.');
    }

    for (var index = 0; index < currentPly; index += 1) {
      final move = _analysisMoves[index];
      final moveData = <String, String>{'from': move.from, 'to': move.to};
      final promotion = move.promotion;

      if (promotion != null && promotion.isNotEmpty) {
        moveData['promotion'] = promotion;
      }

      final moved = analysisGame.move(moveData);

      if (!moved) {
        throw StateError('Analysezug konnte nicht rekonstruiert werden: $move');
      }
    }
  }
}
