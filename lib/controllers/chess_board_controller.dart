import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/stockfish_windows_engine.dart';
import '../models/board_highlights.dart';
import '../models/board_move.dart';
import '../models/player_side.dart';
import '../models/premove_queue.dart';

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

  final PremoveQueue _premoves = PremoveQueue();

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

  bool get hasPremoves => _premoves.isNotEmpty;

  String get premoveText => _premoves.displayText;

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
      premoveSquares: _premoves.highlightedSquares,
      legalTargets: legalTargetsForSelectedSquare(),
    );
  }

  String get statusText {
    if (_isBotThinking) {
      if (_premoves.isNotEmpty) {
        return 'Bot denkt... Premoves gesetzt: ${_premoves.displayText}';
      }

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

    if (_premoves.isNotEmpty) {
      return '$sideToMove am Zug — Bot ist dran. Premoves: ${_premoves.displayText}';
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
    _premoves.clear();
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
    if (!isPlayersTurn && _premoves.isNotEmpty) {
      return _virtualPieceAt(square);
    }

    return _game.get(square);
  }

  bool canHumanMovePiece(String square) {
    if (isGameOver) {
      return false;
    }

    if (isPlayersTurn && !_isBotThinking) {
      final piece = _game.get(square);

      if (piece == null) {
        return false;
      }

      return _isOwnPiece(piece);
    }

    if (!isPlayersTurn) {
      final piece = _virtualPieceAt(square);

      if (piece == null) {
        return false;
      }

      return _isPlayerPiece(piece);
    }

    return false;
  }

  bool canMoveTo({required String from, required String to}) {
    if (isGameOver) {
      return false;
    }

    if (from == to) {
      return false;
    }

    if (isPlayersTurn && !_isBotThinking) {
      return legalTargetsFromSquare(from).contains(to);
    }

    if (!isPlayersTurn) {
      final piece = _virtualPieceAt(from);

      if (piece == null) {
        return false;
      }

      if (!_isPlayerPiece(piece)) {
        return false;
      }

      final targetPiece = _virtualPieceAt(to);

      if (targetPiece != null && _isPlayerPiece(targetPiece)) {
        return false;
      }

      return true;
    }

    return false;
  }

  List<String> legalTargetsForSelectedSquare() {
    if (_selectedSquare == null) {
      return [];
    }

    if (!isPlayersTurn) {
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
    if (isGameOver) {
      return;
    }

    if (!isPlayersTurn) {
      await _onPremoveSquareTap(square);
      return;
    }

    if (_isBotThinking) {
      return;
    }

    final piece = _game.get(square);

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
    if (isGameOver) {
      return false;
    }

    if (!isPlayersTurn || _isBotThinking) {
      return _addPremove(from: from, to: to);
    }

    final moved = _game.move({'from': from, 'to': to, 'promotion': 'q'});

    if (!moved) {
      return false;
    }

    _lastFrom = from;
    _lastTo = to;
    _selectedSquare = null;
    _premoves.clear();

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
    var botMoved = false;

    try {
      final bestMove = await _engine.getBestMoveFromFen(
        fen: _game.fen,
        skillLevel: _skillLevel,
        moveTimeMs: 800,
      );

      if (_isDisposed || currentSearchGeneration != _searchGeneration) {
        return;
      }

      botMoved = _applyUciMove(bestMove);
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

    if (!_isDisposed &&
        currentSearchGeneration == _searchGeneration &&
        botMoved) {
      await _tryPlayNextPremoveIfPossible();
    }
  }

  Future<void> _onPremoveSquareTap(String square) async {
    final piece = _virtualPieceAt(square);

    if (_selectedSquare == null) {
      if (piece == null) {
        _clearPremoves();
        return;
      }

      if (!_isPlayerPiece(piece)) {
        return;
      }

      selectSquare(square);
      return;
    }

    if (_selectedSquare == square) {
      clearSelectedSquare();
      return;
    }

    if (piece != null && _isPlayerPiece(piece)) {
      selectSquare(square);
      return;
    }

    _addPremove(from: _selectedSquare!, to: square);
  }

  bool _addPremove({required String from, required String to}) {
    if (from == to || isGameOver) {
      return false;
    }

    final piece = _virtualPieceAt(from);

    if (piece == null) {
      return false;
    }

    if (!_isPlayerPiece(piece)) {
      return false;
    }

    final targetPiece = _virtualPieceAt(to);

    if (targetPiece != null && _isPlayerPiece(targetPiece)) {
      return false;
    }

    _premoves.add(BoardMove(from: from, to: to, promotion: 'q'));
    _selectedSquare = null;

    _safeNotify();

    return true;
  }

  void _clearPremoves() {
    if (_premoves.isEmpty && _selectedSquare == null) {
      return;
    }

    _premoves.clear();
    _selectedSquare = null;

    _safeNotify();
  }

  Future<void> _tryPlayNextPremoveIfPossible() async {
    if (_premoves.isEmpty) {
      return;
    }

    if (isGameOver || !isPlayersTurn) {
      _safeNotify();
      return;
    }

    final premove = _premoves.popFirst();

    if (premove == null) {
      return;
    }

    final moved = _game.move({
      'from': premove.from,
      'to': premove.to,
      'promotion': premove.promotion ?? 'q',
    });

    if (!moved) {
      _premoves.clear();
      _selectedSquare = null;
      _engineOutput =
          'Premove ungültig: ${premove.from}-${premove.to}. Weitere Premoves gelöscht.';
      _safeNotify();
      return;
    }

    _lastFrom = premove.from;
    _lastTo = premove.to;
    _selectedSquare = null;

    _safeNotify();

    await makeBotMoveIfNeeded();
  }

  bool _applyUciMove(String uciMove) {
    if (uciMove.length < 4 || uciMove == '(none)') {
      return false;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : 'q';

    final moved = _game.move({'from': from, 'to': to, 'promotion': promotion});

    if (!moved) {
      _engineOutput = 'Bot-Zug konnte nicht ausgeführt werden: $uciMove';
      _safeNotify();
      return false;
    }

    _lastFrom = from;
    _lastTo = to;
    _selectedSquare = null;

    _safeNotify();

    return true;
  }

  chess.Piece? _virtualPieceAt(String square) {
    return _virtualBoardAfterPremoves()[square];
  }

  Map<String, chess.Piece> _virtualBoardAfterPremoves() {
    final board = <String, chess.Piece>{};

    for (final square in _allSquares()) {
      final piece = _game.get(square);

      if (piece != null) {
        board[square] = piece;
      }
    }

    for (final move in _premoves.moves) {
      final piece = board.remove(move.from);

      if (piece == null) {
        break;
      }

      if (!_isPlayerPiece(piece)) {
        break;
      }

      board[move.to] = piece;
    }

    return board;
  }

  List<String> _allSquares() {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

    final squares = <String>[];

    for (final file in files) {
      for (final rank in ranks) {
        squares.add('$file$rank');
      }
    }

    return squares;
  }

  bool _isOwnPiece(chess.Piece piece) {
    return piece.color == _game.turn;
  }

  bool _isPlayerPiece(chess.Piece piece) {
    final playerColor = playerIsWhite ? chess.Color.WHITE : chess.Color.BLACK;
    return piece.color == playerColor;
  }

  void _safeNotify() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
