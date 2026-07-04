import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/stockfish_windows_engine.dart';
import '../models/board_highlights.dart';
import '../models/player_side.dart';

class ChessBoardController extends ChangeNotifier {
  ChessBoardController({ChessEngine? engine})
    : _engine = engine ?? StockfishWindowsEngine();

  final chess.Chess _game = chess.Chess();
  final ChessEngine _engine;

  StreamSubscription<String>? _engineSubscription;

  PlayerSide _playerSide = PlayerSide.white;

  String? _selectedSquare;
  String? _lastFrom;
  String? _lastTo;

  int _skillLevel = 0;
  bool _isBotThinking = false;
  String _engineOutput = '-';

  bool _isDisposed = false;
  int _searchGeneration = 0;

  chess.Chess get game => _game;

  PlayerSide get playerSide => _playerSide;

  int get skillLevel => _skillLevel;

  bool get isBotThinking => _isBotThinking;

  String get engineOutput => _engineOutput;

  String get fen => _game.fen;

  String get pgn {
    final currentPgn = _game.pgn();
    return currentPgn.isEmpty ? '-' : currentPgn;
  }

  bool get playerIsWhite => _playerSide == PlayerSide.white;

  bool get isPlayersTurn {
    final whiteToMove = _game.turn == chess.Color.WHITE;

    if (playerIsWhite) {
      return whiteToMove;
    }

    return !whiteToMove;
  }

  bool get isGameOver {
    return _game.game_over ||
        _game.in_checkmate ||
        _game.in_stalemate ||
        _game.in_draw;
  }

  BoardHighlights get highlights {
    return BoardHighlights(
      selectedSquare: _selectedSquare,
      lastFrom: _lastFrom,
      lastTo: _lastTo,
      legalTargets: legalTargetsForSelectedSquare(),
    );
  }

  String get statusText {
    if (_isBotThinking) {
      return 'Bot denkt...';
    }

    if (_game.in_checkmate) {
      return _game.turn == chess.Color.WHITE
          ? 'Schachmatt. Schwarz gewinnt.'
          : 'Schachmatt. Weiß gewinnt.';
    }

    if (_game.in_stalemate) {
      return 'Patt.';
    }

    if (_game.in_draw) {
      return 'Remis.';
    }

    if (_game.in_check) {
      return _game.turn == chess.Color.WHITE
          ? 'Weiß ist im Schach.'
          : 'Schwarz ist im Schach.';
    }

    final sideToMove = _game.turn == chess.Color.WHITE ? 'Weiß' : 'Schwarz';

    if (isPlayersTurn) {
      return '$sideToMove am Zug — du bist dran';
    }

    return '$sideToMove am Zug — Bot ist dran';
  }

  void start() {
    _engineSubscription ??= _engine.output.listen((line) {
      if (_isDisposed) return;

      _engineOutput = line;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _engineSubscription?.cancel();
    unawaited(_engine.stop());
    super.dispose();
  }

  void newGame(PlayerSide side) {
    _searchGeneration++;

    _playerSide = side;
    _game.reset();
    _selectedSquare = null;
    _lastFrom = null;
    _lastTo = null;
    _isBotThinking = false;
    _engineOutput = '-';

    _safeNotify();

    if (_playerSide == PlayerSide.black) {
      unawaited(makeBotMoveIfNeeded());
    }
  }

  void restartGame() {
    newGame(_playerSide);
  }

  void setSkillLevel(int level) {
    if (_isBotThinking) {
      return;
    }

    _skillLevel = level;
    _safeNotify();
  }

  void selectSquare(String square) {
    _selectedSquare = square;
    _safeNotify();
  }

  void clearSelectedSquare() {
    _selectedSquare = null;
    _safeNotify();
  }

  chess.Piece? pieceAt(String square) {
    return _game.get(square);
  }

  bool canHumanMovePiece(String square) {
    if (_isBotThinking || !isPlayersTurn || isGameOver) {
      return false;
    }

    final piece = pieceAt(square);

    if (piece == null) {
      return false;
    }

    return _isOwnPiece(piece);
  }

  List<String> legalTargetsForSelectedSquare() {
    if (_selectedSquare == null) {
      return [];
    }

    return legalTargetsFromSquare(_selectedSquare!);
  }

  List<String> legalTargetsFromSquare(String fromSquare) {
    final moves = _game.moves({'square': fromSquare, 'verbose': true});

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

  Future<void> onSquareTap(String square) async {
    if (_isBotThinking || !isPlayersTurn || isGameOver) {
      return;
    }

    final piece = pieceAt(square);

    if (_selectedSquare == null) {
      if (piece == null) {
        return;
      }

      if (!_isOwnPiece(piece)) {
        return;
      }

      selectSquare(square);
      return;
    }

    if (_selectedSquare == square) {
      clearSelectedSquare();
      return;
    }

    final from = _selectedSquare!;
    final moved = await tryHumanMove(from: from, to: square);

    if (moved) {
      return;
    }

    if (piece != null && _isOwnPiece(piece)) {
      selectSquare(square);
      return;
    }

    clearSelectedSquare();
  }

  Future<bool> tryHumanMove({required String from, required String to}) async {
    final moved = _game.move({'from': from, 'to': to, 'promotion': 'q'});

    if (!moved) {
      return false;
    }

    _lastFrom = from;
    _lastTo = to;
    _selectedSquare = null;

    _safeNotify();

    await makeBotMoveIfNeeded();

    return true;
  }

  Future<void> makeBotMoveIfNeeded() async {
    if (isGameOver) {
      return;
    }

    if (isPlayersTurn) {
      return;
    }

    _isBotThinking = true;
    _safeNotify();

    final currentSearchGeneration = ++_searchGeneration;

    try {
      final bestMove = await _engine.getBestMoveFromFen(
        fen: _game.fen,
        skillLevel: _skillLevel,
        moveTimeMs: 800,
      );

      if (_isDisposed || currentSearchGeneration != _searchGeneration) {
        return;
      }

      _applyUciMove(bestMove);
    } catch (e) {
      if (_isDisposed || currentSearchGeneration != _searchGeneration) {
        return;
      }

      _engineOutput = e.toString();
      _safeNotify();
    } finally {
      if (!_isDisposed && currentSearchGeneration == _searchGeneration) {
        _isBotThinking = false;
        _safeNotify();
      }
    }
  }

  bool _isOwnPiece(chess.Piece piece) {
    return piece.color == _game.turn;
  }

  void _applyUciMove(String uciMove) {
    if (uciMove.length < 4 || uciMove == '(none)') {
      return;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : 'q';

    final moved = _game.move({'from': from, 'to': to, 'promotion': promotion});

    if (!moved) {
      _engineOutput = 'Bot-Zug konnte nicht ausgeführt werden: $uciMove';
      _safeNotify();
      return;
    }

    _lastFrom = from;
    _lastTo = to;
    _selectedSquare = null;

    _safeNotify();
  }

  void _safeNotify() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
