library chess_board_controller;

import 'dart:async';
import 'dart:collection';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/chess_engine_factory.dart';
import '../data/better_bots_database.dart';
import '../data/entities/better_bots_app_state_entity.dart';
import '../engine/personality/cp_loss_move_selector.dart';
import '../engine/personality/fritz19_move_selector.dart';
import '../engine/personality/persona_move_selector.dart';
import '../models/analysis_session.dart';
import '../models/board_highlights.dart';
import '../models/board_move.dart';
import '../models/bot_opening_move.dart';
import '../models/bot_personality.dart';
import '../models/bot_personality_source.dart';
import '../models/engine_analysis_line.dart';
import '../models/engine_strength_mode.dart';
import '../models/fritz19_personality.dart';
import '../models/player_side.dart';
import '../models/premove_queue.dart';

part 'chess_board_controller_parts/chess_board_controller_analysis.dart';
part 'chess_board_controller_parts/chess_board_controller_engine.dart';
part 'chess_board_controller_parts/chess_board_controller_input.dart';
part 'chess_board_controller_parts/chess_board_controller_persistence.dart';
part 'chess_board_controller_parts/chess_board_controller_premoves.dart';
part 'chess_board_controller_parts/chess_board_controller_promotion.dart';
part 'chess_board_controller_parts/chess_board_controller_selection.dart';
part 'chess_board_controller_parts/chess_board_controller_state.dart';
part 'chess_board_controller_parts/chess_board_controller_review.dart';
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
  final List<BotOpeningMove> _selectedOpeningMoves = [];

  BotPersonalitySource _botPersonalitySource =
      BotPersonalitySource.chessiverse;
  BotPersonalitySource? _resolvedRandomPersonalitySource;
  BotPersonality _botPersonality = BotPersonality.random;
  BotPersonality? _resolvedRandomPersonality;
  Fritz19Personality _fritz19Personality = Fritz19Personality.allrounder;
  Fritz19Personality? _resolvedRandomFritz19Personality;
  final List<BotPersonality> _selectedChessiversePersonalities = [];
  final List<Fritz19Personality> _selectedFritz19Personalities = [];
  int _personaCandidateCount = 64;

  _PendingBotSettings? _pendingBotSettings;

  bool _isBotThinking = false;
  String _engineOutput = '-';

  bool _analysisUsedDuringCurrentGame = false;
  bool _resultCountedForCurrentGame = false;
  bool _hasLoadedPersistedState = false;
  TrainingCounterSnapshot _trainingCounterSnapshot =
      const TrainingCounterSnapshot.zero();

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

  /// Halbzug-Index der normalen Partie, der gerade im Brett betrachtet wird.
  /// `null` bedeutet: Live-Stellung am Ende der laufenden Partie.
  /// 0 bedeutet: Startstellung, 1 bedeutet: Stellung nach dem ersten Halbzug.
  int? _normalReviewPly;

  /// Merkt sich die normale Rückblickstellung, aus der heraus Analyse gestartet
  /// wurde. Beim Verlassen der Analyse wird genau dorthin zurückgesprungen.
  int? _normalReviewPlyBeforeAnalysis;

  /// Halbzug-Index, den die Windows-Zugliste während der Analyse hervorhebt.
  /// Die Analyse-Session selbst bleibt die Quelle für das echte Analysebrett.
  int? _analysisMainLinePly;

  chess.Chess get game => _game;

  PlayerSide get playerSide => _playerSide;

  int get skillLevel => _skillLevel;

  EngineStrengthMode get strengthMode => _strengthMode;

  int get uciElo => _uciElo;

  int get cpLossElo => _cpLossElo;

  int get cpLossUciSwitchFullMoveNumber => _cpLossUciSwitchFullMoveNumber;

  BotOpeningMove get botOpeningMove => _botOpeningMove;

  BotOpeningMove get effectiveBotOpeningMove {
    return _resolveSelectedOpening(this);
  }

  UnmodifiableListView<BotOpeningMove> get selectedOpeningMoves {
    return UnmodifiableListView(_selectedOpeningMoves);
  }

  BotPersonalitySource get botPersonalitySource => _botPersonalitySource;

  BotPersonalitySource get effectiveBotPersonalitySource {
    return _controllerEffectiveBotPersonalitySource(this);
  }

  BotPersonality get botPersonality => _botPersonality;

  BotPersonality get effectiveBotPersonality {
    return _controllerEffectiveBotPersonality(this);
  }

  Fritz19Personality get fritz19Personality => _fritz19Personality;

  Fritz19Personality get effectiveFritz19Personality {
    return _controllerEffectiveFritz19Personality(this);
  }

  UnmodifiableListView<BotPersonality> get selectedChessiversePersonalities {
    return UnmodifiableListView(_selectedChessiversePersonalities);
  }

  UnmodifiableListView<Fritz19Personality> get selectedFritz19Personalities {
    return UnmodifiableListView(_selectedFritz19Personalities);
  }

  String get activePersonalityLabel {
    return _controllerActivePersonalityLabel(this);
  }

  int get personaCandidateCount => _personaCandidateCount;

  bool get isBotThinking => _isBotThinking;

  String get engineOutput => _engineOutput;

  bool get isAnalysisMode => _analysisSession != null;

  bool get isAnalysisBranchActive {
    return _analysisSession?.isBranchActive ?? false;
  }

  bool get analysisUsedDuringCurrentGame {
    return _analysisUsedDuringCurrentGame;
  }

  TrainingCounterSnapshot get trainingCounterSnapshot {
    _controllerRefreshTrainingCounterSnapshot(this);
    return _trainingCounterSnapshot;
  }

  bool get canStartAnalysisMode {
    if (isAnalysisMode || _isBotThinking) {
      return false;
    }

    if (isNormalReviewMode) {
      return true;
    }

    if (isGameOver) {
      return true;
    }

    return isPlayersTurn;
  }

  bool get canToggleAnalysisMode {
    return isAnalysisMode || canStartAnalysisMode;
  }

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

  bool get isNormalReviewMode => _controllerIsNormalReviewMode(this);

  int get currentMainLinePly => _controllerCurrentMainLinePly(this);

  int get mainLinePlyCount => _normalGameMoves.length;

  bool get canNavigateMainLineBack {
    return _controllerCanNavigateMainLineBack(this);
  }

  bool get canNavigateMainLineForward {
    return _controllerCanNavigateMainLineForward(this);
  }

  List<ChessMoveListEntry> get mainLineMoveEntries {
    return _controllerMainLineMoveEntries(this);
  }

  String get fen => _analysisSession?.fen ?? _controllerDisplayedNormalFen(this);

  String get pgn {
    final analysisPgn = _analysisSession?.pgn;

    if (analysisPgn != null) {
      return analysisPgn;
    }

    final currentPgn = _game.pgn();
    return currentPgn.isEmpty ? '-' : currentPgn;
  }

  bool get playerIsWhite => _playerSide == PlayerSide.white;

  bool get hasPremoves => !isAnalysisMode && !isNormalReviewMode && _premoves.isNotEmpty;

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

    if (isNormalReviewMode) {
      return false;
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

    final displayGame = _controllerDisplayedNormalGame(this);

    return displayGame.game_over ||
        displayGame.in_checkmate ||
        displayGame.in_stalemate ||
        displayGame.in_draw;
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

  void restartTrainingCounterGame() {
    _controllerRestartTrainingCounterGame(this);
  }

  void toggleAnalysisMode() => _controllerToggleAnalysisMode(this);

  Future<void> stepAnalysisBack() => _controllerStepAnalysisBack(this);

  Future<void> stepAnalysisForward() => _controllerStepAnalysisForward(this);

  Future<void> jumpAnalysisToStart() => _controllerJumpAnalysisToStart(this);

  Future<void> jumpAnalysisToEnd() => _controllerJumpAnalysisToEnd(this);

  void stepMainLineBack() => _controllerStepMainLineBack(this);

  void stepMainLineForward() => _controllerStepMainLineForward(this);

  void jumpMainLineToStart() => _controllerJumpMainLineToStart(this);

  void jumpMainLineToEnd() => _controllerJumpMainLineToEnd(this);

  Future<void> jumpToMainLinePly(int ply) {
    return _controllerJumpToMainLinePly(this, ply);
  }

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
    return _controllerSetBotOpeningMove(this, move);
  }

  void toggleOpeningMoveSelection(BotOpeningMove move) {
    return _controllerToggleOpeningMoveSelection(this, move);
  }

  void clearOpeningMoveSelection() {
    return _controllerClearOpeningMoveSelection(this);
  }

  void setBotPersonality(BotPersonality personality) {
    return _controllerSetBotPersonality(this, personality);
  }

  void toggleChessiversePersonalitySelection(BotPersonality personality) {
    return _controllerToggleChessiversePersonalitySelection(this, personality);
  }

  void setFritz19Personality(Fritz19Personality personality) {
    return _controllerSetFritz19Personality(this, personality);
  }

  void toggleFritz19PersonalitySelection(Fritz19Personality personality) {
    return _controllerToggleFritz19PersonalitySelection(this, personality);
  }

  void clearPersonalitySelection() {
    return _controllerClearPersonalitySelection(this);
  }

  void setAllPersonalitiesRandom() {
    return _controllerSetAllPersonalitiesRandom(this);
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



