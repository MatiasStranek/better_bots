library chess_board_controller;

import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/stockfish_windows_engine.dart';
import '../models/board_highlights.dart';
import '../models/board_move.dart';
import '../models/player_side.dart';
import '../models/premove_queue.dart';

part 'chess_board_controller_parts/chess_board_controller_engine.dart';
part 'chess_board_controller_parts/chess_board_controller_input.dart';
part 'chess_board_controller_parts/chess_board_controller_premoves.dart';
part 'chess_board_controller_parts/chess_board_controller_promotion.dart';
part 'chess_board_controller_parts/chess_board_controller_selection.dart';
part 'chess_board_controller_parts/chess_board_controller_state.dart';
part 'chess_board_controller_parts/chess_board_controller_virtual_board.dart';

typedef PromotionChoiceCallback =
    Future<String?> Function({
      required String from,
      required String to,
      required PlayerSide playerSide,
    });

class ChessBoardController extends ChangeNotifier {
  ChessBoardController({
    ChessEngine? engine,
    PromotionChoiceCallback? onPromotionChoiceRequested,
  }) : _engine = engine ?? StockfishWindowsEngine(),
       _onPromotionChoiceRequested = onPromotionChoiceRequested;

  final chess.Chess _game = chess.Chess();
  final ChessEngine _engine;
  final PromotionChoiceCallback? _onPromotionChoiceRequested;

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

  BoardHighlights get highlights => _controllerHighlights(this);

  String get statusText => _controllerStatusText(this);

  void start() => _controllerStart(this);

  @override
  void dispose() {
    _isDisposed = true;
    _engineSubscription?.cancel();
    unawaited(_engine.stop());
    super.dispose();
  }

  void newGame(PlayerSide side) => _controllerNewGame(this, side);

  void restartGame() => newGame(_playerSide);

  void setSkillLevel(int level) => _controllerSetSkillLevel(this, level);

  void selectSquare(String square) => _controllerSelectSquare(this, square);

  void clearSelectedSquare() => _controllerClearSelectedSquare(this);

  chess.Piece? pieceAt(String square) => _controllerPieceAt(this, square);

  bool canHumanMovePiece(String square) {
    return _controllerCanHumanMovePiece(this, square);
  }

  bool canMoveTo({required String from, required String to}) {
    return _controllerCanMoveTo(this, from: from, to: to);
  }

  List<String> legalTargetsForSelectedSquare() {
    return _controllerLegalTargetsForSelectedSquare(this);
  }

  List<String> legalTargetsFromSquare(String fromSquare) {
    return _controllerLegalTargetsFromSquare(this, fromSquare);
  }

  Future<void> onSquareTap(String square) {
    return _controllerOnSquareTap(this, square);
  }

  Future<bool> tryHumanMove({
    required String from,
    required String to,
    String? promotion,
  }) {
    return _controllerTryHumanMove(
      this,
      from: from,
      to: to,
      promotion: promotion,
    );
  }

  Future<void> makeBotMoveIfNeeded() {
    return _controllerMakeBotMoveIfNeeded(this);
  }

  Future<bool> loadFenPosition(String fenInput) {
    return _controllerLoadFenPosition(this, fenInput);
  }
}
