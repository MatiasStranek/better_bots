library chess_board_controller;

import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/chess_engine_factory.dart';
import '../engine/personality/cp_loss_move_selector.dart';
import '../engine/personality/persona_move_selector.dart';
import '../models/analysis_session.dart';
import '../models/board_highlights.dart';
import '../models/board_move.dart';
import '../models/bot_opening_move.dart';
import '../models/bot_personality.dart';
import '../models/engine_analysis_line.dart';
import '../models/engine_strength_mode.dart';
import '../models/player_side.dart';
import '../models/premove_queue.dart';

part 'chess_board_controller_parts/chess_board_controller_analysis.dart';
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
    ChessEngine? analysisEngine,
    PromotionChoiceCallback? onPromotionChoiceRequested,
  }) : _engine = engine ?? ChessEngineFactory.createDefaultEngine(),
       _analysisEngine = analysisEngine ?? ChessEngineFactory.createDefaultEngine(),
       _onPromotionChoiceRequested = onPromotionChoiceRequested;

  final chess.Chess _game = chess.Chess();
  final ChessEngine _engine;
  final ChessEngine _analysisEngine;
  final PromotionChoiceCallback? _onPromotionChoiceRequested;

  StreamSubscription<String>? _engineSubscription;

  PlayerSide _playerSide = PlayerSide.white;

  String? _selectedSquare;
  String? _lastFrom;
  String? _lastTo;

  final PremoveQueue _premoves = PremoveQueue();

  int _skillLevel = 0;
  EngineStrengthMode _strengthMode = EngineStrengthMode.cpLossElo;
  int _uciElo = 1320;
  int _cpLossElo = 1600;
  int _cpLossUciSwitchFullMoveNumber = 11;

  BotOpeningMove _botOpeningMove = BotOpeningMove.random;
  bool _openingLogicAllowed = true;
  BotOpeningMove? _resolvedRandomOpeningMove;

  BotPersonality _botPersonality = BotPersonality.random;
  BotPersonality? _resolvedRandomPersonality;
  int _personaCandidateCount = 64;

  bool _isBotThinking = false;
  String _engineOutput = '-';

  bool _isDisposed = false;
  int _searchGeneration = 0;

  AnalysisSession? _analysisSession;
  int _analysisGeneration = 0;
  bool _analysisSearchInFlight = false;
  bool _analysisSearchQueued = false;

  /// Start-FEN der aktuell laufenden Originalpartie.
  /// Diese FEN wird zusammen mit [_normalGameMoves] benutzt, damit der
  /// Analysemodus nicht nur die aktuelle Stellung sieht, sondern die komplette
  /// bisherige Partie als navigierbare Hauptvariante bekommt.
  String _normalGameStartFen = _defaultStartFen;

  /// UCI-Zugliste der Originalpartie seit [_normalGameStartFen].
  /// Diese Liste wird ausschließlich beim normalen Spiel fortgeschrieben und
  /// niemals aus der Analyse-Session zurückkopiert.
  final List<BoardMove> _normalGameMoves = [];

  chess.Chess get game => _game;

  PlayerSide get playerSide => _playerSide;

  int get skillLevel => _skillLevel;

  EngineStrengthMode get strengthMode => _strengthMode;

  int get uciElo => _uciElo;

  int get cpLossElo => _cpLossElo;

  int get cpLossUciSwitchFullMoveNumber => _cpLossUciSwitchFullMoveNumber;

  BotOpeningMove get botOpeningMove => _botOpeningMove;

  BotPersonality get botPersonality => _botPersonality;

  BotPersonality get effectiveBotPersonality {
    return _controllerEffectiveBotPersonality(this);
  }

  int get personaCandidateCount => _personaCandidateCount;

  bool get isBotThinking => _isBotThinking;

  String get engineOutput => _engineOutput;

  bool get isAnalysisMode => _analysisSession != null;

  bool get isAnalysisThinking => _analysisSession?.isAnalyzing ?? false;

  bool get canNavigateAnalysisBack {
    return _analysisSession?.canStepBack ?? false;
  }

  bool get canNavigateAnalysisForward {
    return _analysisSession?.canStepForward ?? false;
  }

  List<EngineAnalysisLine> get analysisLines {
    return _analysisSession?.topLines ?? const [];
  }

  String get fen => _analysisSession?.fen ?? _game.fen;

  String get pgn {
    final analysisPgn = _analysisSession?.pgn;

    if (analysisPgn != null) {
      return analysisPgn;
    }

    final currentPgn = _game.pgn();
    return currentPgn.isEmpty ? '-' : currentPgn;
  }

  bool get playerIsWhite => _playerSide == PlayerSide.white;

  bool get hasPremoves => !isAnalysisMode && _premoves.isNotEmpty;

  String get premoveText {
    if (isAnalysisMode) {
      return '-';
    }

    return _premoves.displayText;
  }

  bool get isPlayersTurn {
    if (isAnalysisMode) {
      return true;
    }

    final whiteToMove = _game.turn == chess.Color.WHITE;

    if (playerIsWhite) {
      return whiteToMove;
    }

    return !whiteToMove;
  }

  bool get isGameOver {
    final analysisSession = _analysisSession;

    if (analysisSession != null) {
      return analysisSession.isGameOver;
    }

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
    _analysisGeneration++;
    _engineSubscription?.cancel();
    unawaited(_engine.stop());
    unawaited(_analysisEngine.stop());
    super.dispose();
  }

  void newGame(PlayerSide side) {
    if (isAnalysisMode) {
      return;
    }

    _openingLogicAllowed = true;
    _resolvedRandomOpeningMove = null;
    _resolvedRandomPersonality = null;
    _controllerNewGame(this, side);
  }

  void restartGame() {
    if (isAnalysisMode) {
      return;
    }

    newGame(_playerSide);
  }

  void toggleAnalysisMode() => _controllerToggleAnalysisMode(this);

  Future<void> stepAnalysisBack() => _controllerStepAnalysisBack(this);

  Future<void> stepAnalysisForward() => _controllerStepAnalysisForward(this);

  void setSkillLevel(int level) => _controllerSetSkillLevel(this, level);

  void setStrengthMode(EngineStrengthMode mode) {
    return _controllerSetStrengthMode(this, mode);
  }

  void setUciElo(int elo) => _controllerSetUciElo(this, elo);

  void setCpLossElo(int elo) => _controllerSetCpLossElo(this, elo);

  void setCpLossUciSwitchFullMoveNumber(int fullMoveNumber) {
    return _controllerSetCpLossUciSwitchFullMoveNumber(this, fullMoveNumber);
  }

  void setBotOpeningMove(BotOpeningMove move) {
    if (_isBotThinking || isAnalysisMode) {
      return;
    }

    _botOpeningMove = move;
    _resolvedRandomOpeningMove = null;
    notifyListeners();
  }

  void setBotPersonality(BotPersonality personality) {
    return _controllerSetBotPersonality(this, personality);
  }

  void setPersonaCandidateCount(int candidateCount) {
    return _controllerSetPersonaCandidateCount(this, candidateCount);
  }

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
    if (isAnalysisMode) {
      return Future<bool>.value(false);
    }

    _openingLogicAllowed = false;
    _resolvedRandomOpeningMove = null;
    _resolvedRandomPersonality = null;
    return _controllerLoadFenPosition(this, fenInput);
  }
}
