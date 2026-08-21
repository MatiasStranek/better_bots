import 'package:chess/chess.dart' as chess;

import 'board_move.dart';
import 'engine_analysis_line.dart';

class AnalysisSession {
  AnalysisSession({
    required this.startFen,
    List<BoardMove> initialMoves = const <BoardMove>[],
    int? initialPly,
  }) : analysisGame = chess.Chess() {
    final loaded = analysisGame.load(startFen);

    if (!loaded) {
      throw ArgumentError.value(startFen, 'startFen', 'Ungültige Analyse-FEN');
    }

    _analysisMoves.addAll(initialMoves);
    _rebuildMainLineFenCache();
    currentPly = (initialPly ?? _analysisMoves.length)
        .clamp(0, _analysisMoves.length)
        .toInt();
    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();
  }

  /// Ausgangs-FEN der Originalpartie.
  /// Bei einer normalen Partie ist das die Startstellung; bei einer geladenen
  /// FEN ist es genau diese geladene FEN. Die aktuelle Stellung entsteht durch
  /// Replay der Hauptvariante oder des temporären Analysezweigs.
  final String startFen;

  /// Komplett getrenntes Analysebrett. Dieses Objekt darf nie in _game kopiert
  /// werden und _game darf nie aus diesem Objekt ersetzt werden.
  final chess.Chess analysisGame;

  /// Hauptvariante der übernommenen Partie. Diese Liste wird durch temporäre
  /// Analysezweige nicht mehr überschrieben.
  final List<BoardMove> _analysisMoves = [];

  /// FEN jeder Hauptlinien-Stellung: Index 0 ist die Startstellung, danach
  /// folgt jeweils die Stellung nach dem entsprechenden Halbzug. Dadurch kann
  /// die Zugliste den vorhandenen Analyse-Cache abfragen, ohne bei jedem
  /// UI-Rebuild die komplette Partie erneut abspielen zu müssen.
  final List<String> _mainLineFens = [];

  /// Temporärer Zweig ab [_branchStartPly]. Der Zweig lebt nur innerhalb der
  /// Analyse-Session und wird verworfen, sobald man zurück bis zum Abzweigpunkt
  /// navigiert.
  final List<BoardMove> _branchMoves = [];
  int? _branchStartPly;

  /// Zusammengefasste Tiefe-20-Analysen pro Analyse-FEN.
  /// Es werden keine kompletten historischen Läufe gespeichert. Pro Zug bleiben
  /// nur laufende Summe, Trefferzahl und die zuletzt benötigten Anzeigedaten
  /// erhalten. Die Map lebt nur innerhalb der AnalysisSession.
  final Map<String, _PositionAnalysisAggregate> _analysisAggregatesByFen = {};

  int currentPly = 0;

  List<EngineAnalysisLine> topLines = const [];

  bool isAnalyzing = false;

  String statusText = 'Analysemodus aktiv.';

  bool get isBranchActive {
    return _branchStartPly != null;
  }

  /// Synchronisiert die Hauptvariante mit der inzwischen weitergespielten
  /// Partie, ohne die bereits gesammelten Analyse-Aggregate zu verwerfen.
  /// Temporäre Analysezweige werden beim erneuten Öffnen bewusst verlassen;
  /// ihre FEN-basierten Aggregate bleiben jedoch im Cache erhalten.
  void syncMainLine({
    required List<BoardMove> moves,
    required int initialPly,
  }) {
    _analysisMoves
      ..clear()
      ..addAll(moves);
    _rebuildMainLineFenCache();
    _clearBranch();
    currentPly = initialPly.clamp(0, _analysisMoves.length).toInt();
    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();
    isAnalyzing = false;
  }

  List<BoardMove> get analysisMoves {
    return List.unmodifiable(_activeMoves);
  }

  bool get canStepBack {
    return currentPly > 0;
  }

  bool get canStepForward {
    return currentPly < _activeMoveCount;
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
    if (currentPly <= 0 || currentPly > _activeMoveCount) {
      return null;
    }

    return _activeMoveAt(currentPly - 1).from;
  }

  String? get lastTo {
    if (currentPly <= 0 || currentPly > _activeMoveCount) {
      return null;
    }

    return _activeMoveAt(currentPly - 1).to;
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

    final newMove = BoardMove(
      from: from,
      to: to,
      promotion: normalizedPromotion,
    );

    if (isBranchActive) {
      _playMoveInsideBranch(newMove);
    } else if (currentPly < _analysisMoves.length) {
      _playMoveFromMainlinePast(newMove);
    } else {
      _playMoveFromMainlineEnd(newMove);
    }

    restoreCompletedLinesForCurrentFen();

    return true;
  }

  bool stepBack() {
    if (!canStepBack) {
      return false;
    }

    currentPly -= 1;

    final branchStartPly = _branchStartPly;
    final leftBranch = branchStartPly != null && currentPly <= branchStartPly;

    if (leftBranch) {
      currentPly = branchStartPly;
      _clearBranch();
    }

    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();

    if (leftBranch) {
      statusText = hasCompletedLinesForCurrentFen()
          ? 'Analysezweig verlassen. Hauptvariante geladen.'
          : 'Analysezweig verlassen.';
    } else {
      statusText = hasCompletedLinesForCurrentFen()
          ? 'Analyse: einen Zug zurück. Gespeicherte Tiefe-20-Analyse geladen.'
          : 'Analyse: einen Zug zurück.';
    }

    return true;
  }

  bool stepForward() {
    if (!canStepForward) {
      return false;
    }

    currentPly += 1;
    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();
    statusText = hasCompletedLinesForCurrentFen()
        ? 'Analyse: einen Zug vor. Gespeicherte Tiefe-20-Analyse geladen.'
        : 'Analyse: einen Zug vor.';

    return true;
  }

  bool jumpToStart() {
    if (!canStepBack) {
      return false;
    }

    currentPly = 0;
    _clearBranch();
    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();
    statusText = hasCompletedLinesForCurrentFen()
        ? 'Analyse: Grundstellung. Gespeicherte Tiefe-20-Analyse geladen.'
        : 'Analyse: Grundstellung.';

    return true;
  }

  bool jumpToEnd() {
    if (!canStepForward) {
      return false;
    }

    currentPly = _activeMoveCount;
    _rebuildCurrentPosition();
    restoreCompletedLinesForCurrentFen();
    statusText = hasCompletedLinesForCurrentFen()
        ? 'Analyse: letzter verfügbarer Zug. Gespeicherte Tiefe-20-Analyse geladen.'
        : 'Analyse: letzter verfügbarer Zug.';

    return true;
  }

  int get completedAnalysisCountForCurrentFen {
    return _analysisAggregatesByFen[fen]?.completedRuns ?? 0;
  }

  Set<int> get completedMainLineAnalysisPlies {
    final completedPlies = <int>{};

    for (var ply = 0; ply < _mainLineFens.length; ply += 1) {
      final aggregate = _analysisAggregatesByFen[_mainLineFens[ply]];

      if (aggregate != null && aggregate.completedRuns > 0) {
        completedPlies.add(ply);
      }
    }

    return Set<int>.unmodifiable(completedPlies);
  }

  bool hasCompletedLinesForCurrentFen({int targetDepth = 20}) {
    final aggregate = _analysisAggregatesByFen[fen];

    if (aggregate == null || aggregate.completedRuns <= 0) {
      return false;
    }

    final cachedLines = aggregate.rankedTopLines(
      targetDepth: targetDepth,
      sideToMove: analysisGame.turn,
    );
    return cachedLines.isNotEmpty &&
        _linesReachedTargetDepth(cachedLines, targetDepth: targetDepth);
  }

  bool restoreCompletedLinesForCurrentFen({int targetDepth = 20}) {
    final aggregate = _analysisAggregatesByFen[fen];

    if (aggregate != null && aggregate.completedRuns > 0) {
      final cachedLines = aggregate.rankedTopLines(
        targetDepth: targetDepth,
        sideToMove: analysisGame.turn,
      );

      if (cachedLines.isNotEmpty &&
          _linesReachedTargetDepth(cachedLines, targetDepth: targetDepth)) {
        topLines = cachedLines;
        return true;
      }
    }

    topLines = const [];
    return false;
  }

  void updateLiveTopLinesForFen({
    required String fen,
    required List<EngineAnalysisLine> lines,
  }) {
    if (fen != this.fen) {
      return;
    }

    final sortedLines = _formatLinesForFen(fen: fen, lines: lines);
    topLines = List.unmodifiable(sortedLines.take(5));
  }

  bool addCompletedAnalysisRunForFen({
    required String fen,
    required List<EngineAnalysisLine> lines,
    int targetDepth = 20,
  }) {
    if (fen != this.fen) {
      return false;
    }

    final sortedLines = _formatLinesForFen(fen: fen, lines: lines)
        .where((line) => line.isValidMove)
        .take(5)
        .toList(growable: false);

    if (!_linesReachedTargetDepth(sortedLines, targetDepth: targetDepth)) {
      return false;
    }

    final aggregate = _analysisAggregatesByFen.putIfAbsent(
      fen,
      _PositionAnalysisAggregate.new,
    );

    aggregate.addRun(sortedLines);
    topLines = aggregate.rankedTopLines(
      targetDepth: targetDepth,
      sideToMove: analysisGame.turn,
    );
    return true;
  }

  void clearTopLines() {
    topLines = const [];
  }

  int get _activeMoveCount {
    final branchStartPly = _branchStartPly;

    if (branchStartPly == null) {
      return _analysisMoves.length;
    }

    return branchStartPly + _branchMoves.length;
  }

  List<BoardMove> get _activeMoves {
    final branchStartPly = _branchStartPly;

    if (branchStartPly == null) {
      return List<BoardMove>.from(_analysisMoves);
    }

    return <BoardMove>[
      ..._analysisMoves.take(branchStartPly),
      ..._branchMoves,
    ];
  }

  BoardMove _activeMoveAt(int index) {
    final branchStartPly = _branchStartPly;

    if (branchStartPly == null || index < branchStartPly) {
      return _analysisMoves[index];
    }

    return _branchMoves[index - branchStartPly];
  }

  void _playMoveInsideBranch(BoardMove newMove) {
    final branchStartPly = _branchStartPly!;
    final relativePly = currentPly - branchStartPly;

    if (relativePly < _branchMoves.length) {
      final nextBranchMove = _branchMoves[relativePly];

      if (_sameMove(nextBranchMove, newMove)) {
        currentPly += 1;
        statusText = 'Analysezweig: vorhandenen Zug gespielt.';
        return;
      }

      _branchMoves.removeRange(relativePly, _branchMoves.length);
    }

    _branchMoves.add(newMove);
    currentPly = branchStartPly + _branchMoves.length;
    statusText = 'Temporärer Analysezweig gespielt: $newMove';
  }

  void _playMoveFromMainlinePast(BoardMove newMove) {
    final nextMainMove = _analysisMoves[currentPly];

    if (_sameMove(nextMainMove, newMove)) {
      currentPly += 1;
      statusText = 'Analyse: Hauptvariante fortgesetzt.';
      return;
    }

    _branchStartPly = currentPly;
    _branchMoves
      ..clear()
      ..add(newMove);
    currentPly = _branchStartPly! + _branchMoves.length;
    statusText = 'Temporärer Analysezweig erstellt: $newMove';
  }

  void _playMoveFromMainlineEnd(BoardMove newMove) {
    _branchStartPly = currentPly;
    _branchMoves
      ..clear()
      ..add(newMove);
    currentPly = _branchStartPly! + _branchMoves.length;
    statusText = 'Temporärer Analysezweig erstellt: $newMove';
  }

  void _clearBranch() {
    _branchStartPly = null;
    _branchMoves.clear();
  }

  bool _sameMove(BoardMove left, BoardMove right) {
    return left.from == right.from &&
        left.to == right.to &&
        (left.promotion ?? '') == (right.promotion ?? '');
  }

  List<EngineAnalysisLine> _formatLinesForFen({
    required String fen,
    required List<EngineAnalysisLine> lines,
  }) {
    final sortedLines = List<EngineAnalysisLine>.from(lines)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return sortedLines.map((line) {
      final existingShortMove = line.shortMove?.trim();

      if (existingShortMove != null && existingShortMove.isNotEmpty) {
        return line;
      }

      return line.copyWith(
        shortMove: _shortMoveFromUci(fen, line.uciMove),
      );
    }).toList(growable: false);
  }

  bool _linesReachedTargetDepth(
    List<EngineAnalysisLine> lines, {
    required int targetDepth,
  }) {
    if (lines.isEmpty) {
      return false;
    }

    return lines.every((line) => line.depth >= targetDepth);
  }

  String _shortMoveFromUci(String fen, String uciMove) {
    if (uciMove.length < 4 || uciMove == '(none)') {
      return uciMove;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : '';

    final scratch = chess.Chess();
    final loaded = scratch.load(fen);

    if (!loaded) {
      return _fallbackShortMoveFromUci(uciMove);
    }

    final piece = scratch.get(from);
    final targetPiece = scratch.get(to);
    final moveData = <String, String>{'from': from, 'to': to};

    if (promotion.isNotEmpty) {
      moveData['promotion'] = promotion.toLowerCase();
    }

    final moved = scratch.move(moveData);

    if (moved) {
      if (scratch.history.isNotEmpty) {
        final san = scratch.history.last.toString().trim();

        if (_looksLikeSan(san)) {
          return _withCheckOrMateSuffix(san, scratch);
        }
      }

      return _fallbackShortMoveFromUci(
        uciMove,
        movingPiece: piece,
        targetPiece: targetPiece,
        postMoveGame: scratch,
      );
    }

    return _fallbackShortMoveFromUci(
      uciMove,
      movingPiece: piece,
      targetPiece: targetPiece,
    );
  }

  bool _looksLikeSan(String value) {
    if (value.isEmpty || value.length > 12) {
      return false;
    }

    final lower = value.toLowerCase();

    if (lower.contains('move') ||
        lower.contains('instance') ||
        value.contains('{') ||
        value.contains('}')) {
      return false;
    }

    return true;
  }

  String _fallbackShortMoveFromUci(
    String uciMove, {
    chess.Piece? movingPiece,
    chess.Piece? targetPiece,
    chess.Chess? postMoveGame,
  }) {
    if (uciMove.length < 4 || uciMove == '(none)') {
      return uciMove;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : '';

    if (movingPiece != null && _isKing(movingPiece)) {
      if ((from == 'e1' && to == 'g1') || (from == 'e8' && to == 'g8')) {
        return 'O-O';
      }

      if ((from == 'e1' && to == 'c1') || (from == 'e8' && to == 'c8')) {
        return 'O-O-O';
      }
    }

    final isPawn = movingPiece == null || _isPawn(movingPiece);
    final isCapture = targetPiece != null || (isPawn && from[0] != to[0]);
    final promotionText = promotion.isEmpty ? '' : '=${promotion.toUpperCase()}';
    final checkSuffix = postMoveGame == null
        ? ''
        : _checkOrMateSuffix(postMoveGame);

    if (isPawn) {
      if (isCapture) {
        return '${from[0]}x$to$promotionText$checkSuffix';
      }

      return '$to$promotionText$checkSuffix';
    }

    final pieceLetter = _pieceLetter(movingPiece);
    final captureText = isCapture ? 'x' : '';

    return '$pieceLetter$captureText$to$promotionText$checkSuffix';
  }

  String _withCheckOrMateSuffix(String san, chess.Chess postMoveGame) {
    if (san.endsWith('#') || san.endsWith('+')) {
      return san;
    }

    return '$san${_checkOrMateSuffix(postMoveGame)}';
  }

  String _checkOrMateSuffix(chess.Chess postMoveGame) {
    if (postMoveGame.in_checkmate) {
      return '#';
    }

    if (postMoveGame.in_check) {
      return '+';
    }

    return '';
  }

  String _pieceLetter(chess.Piece? piece) {
    if (piece == null) {
      return '';
    }

    final typeText = piece.type.toString().toLowerCase();

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

    return '';
  }

  bool _isPawn(chess.Piece piece) {
    final typeText = piece.type.toString().toLowerCase();

    return typeText == 'p' ||
        typeText.endsWith('.p') ||
        typeText.contains('pawn');
  }

  bool _isKing(chess.Piece piece) {
    final typeText = piece.type.toString().toLowerCase();

    return typeText == 'k' ||
        typeText.endsWith('.k') ||
        typeText.contains('king');
  }

  void _rebuildMainLineFenCache() {
    final replayGame = chess.Chess();
    final loaded = replayGame.load(startFen);

    if (!loaded) {
      throw StateError('Analyse-Start-FEN konnte nicht erneut geladen werden.');
    }

    _mainLineFens
      ..clear()
      ..add(replayGame.fen);

    for (final move in _analysisMoves) {
      final moveData = <String, String>{'from': move.from, 'to': move.to};
      final promotion = move.promotion;

      if (promotion != null && promotion.isNotEmpty) {
        moveData['promotion'] = promotion;
      }

      final moved = replayGame.move(moveData);

      if (!moved) {
        throw StateError('Analysezug konnte nicht rekonstruiert werden: $move');
      }

      _mainLineFens.add(replayGame.fen);
    }
  }

  void _rebuildCurrentPosition() {
    final loaded = analysisGame.load(startFen);

    if (!loaded) {
      throw StateError('Analyse-Start-FEN konnte nicht erneut geladen werden.');
    }

    for (var index = 0; index < currentPly; index += 1) {
      final move = _activeMoveAt(index);
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

const double _analysisMateBaseScore = 100000.0;
const double _analysisMateStepScore = 100.0;
const double _analysisMateDisplayThreshold = 90000.0;

class _PositionAnalysisAggregate {
  int completedRuns = 0;

  final Map<String, _MoveAnalysisAggregate> _movesByUci = {};

  void addRun(List<EngineAnalysisLine> lines) {
    final seenMoves = <String>{};

    for (final line in lines) {
      final uciMove = line.uciMove.trim();

      if (!line.isValidMove || !seenMoves.add(uciMove)) {
        continue;
      }

      final moveAggregate = _movesByUci.putIfAbsent(
        uciMove,
        () => _MoveAnalysisAggregate(uciMove: uciMove),
      );

      moveAggregate.addSample(line);
    }

    completedRuns += 1;
  }

  List<EngineAnalysisLine> rankedTopLines({
    required int targetDepth,
    required chess.Color sideToMove,
  }) {
    final scoreSign = sideToMove == chess.Color.WHITE ? 1.0 : -1.0;
    final rankedMoves = _movesByUci.values.toList(growable: false)
      ..sort((left, right) {
        final leftRankingScore = left.averageNormalizedScore * scoreSign;
        final rightRankingScore = right.averageNormalizedScore * scoreSign;
        final scoreOrder = rightRankingScore.compareTo(leftRankingScore);

        if (scoreOrder != 0) {
          return scoreOrder;
        }

        return left.uciMove.compareTo(right.uciMove);
      });

    return List<EngineAnalysisLine>.unmodifiable([
      for (var index = 0; index < rankedMoves.length && index < 5; index++)
        rankedMoves[index].toEngineAnalysisLine(
          rank: index + 1,
          targetDepth: targetDepth,
        ),
    ]);
  }
}

class _MoveAnalysisAggregate {
  _MoveAnalysisAggregate({required this.uciMove});

  final String uciMove;

  double _normalizedScoreSum = 0;
  int _sampleCount = 0;
  int _mateSampleCount = 0;
  int? _mateSign;
  int _absoluteMateDistanceSum = 0;
  String? _shortMove;
  List<String> _latestPv = const [];

  double get averageNormalizedScore {
    if (_sampleCount <= 0) {
      return 0;
    }

    return _normalizedScoreSum / _sampleCount;
  }

  void addSample(EngineAnalysisLine line) {
    _normalizedScoreSum += _normalizedScore(line);
    _sampleCount += 1;
    _shortMove = line.shortMove;
    _latestPv = List<String>.unmodifiable(line.pv);

    final mate = line.mate;
    if (mate != null) {
      _mateSampleCount += 1;
      _absoluteMateDistanceSum += mate.abs();
      final sign = mate == 0 ? 1 : mate.sign;
      _mateSign = _mateSign == null || _mateSign == sign ? sign : 0;
    }
  }

  EngineAnalysisLine toEngineAnalysisLine({
    required int rank,
    required int targetDepth,
  }) {
    final allSamplesAreCompatibleMateScores = _sampleCount > 0 &&
        _mateSampleCount == _sampleCount &&
        _mateSign != null &&
        _mateSign != 0;

    if (allSamplesAreCompatibleMateScores) {
      final averageDistance =
          (_absoluteMateDistanceSum / _mateSampleCount)
              .round()
              .clamp(0, 999)
              .toInt();

      return EngineAnalysisLine(
        rank: rank,
        depth: targetDepth,
        scoreCp: null,
        mate: _mateSign! * averageDistance,
        uciMove: uciMove,
        shortMove: _shortMove,
        pv: _latestPv,
      );
    }

    final averageScore = averageNormalizedScore;

    if (averageScore.abs() >= _analysisMateDisplayThreshold) {
      final approximateDistance =
          ((_analysisMateBaseScore - averageScore.abs()) /
                  _analysisMateStepScore)
              .round()
              .clamp(0, 999)
              .toInt();
      final mateSign = averageScore < 0 ? -1 : 1;

      return EngineAnalysisLine(
        rank: rank,
        depth: targetDepth,
        scoreCp: null,
        mate: mateSign * approximateDistance,
        uciMove: uciMove,
        shortMove: _shortMove,
        pv: _latestPv,
      );
    }

    return EngineAnalysisLine(
      rank: rank,
      depth: targetDepth,
      scoreCp: averageScore.round(),
      mate: null,
      uciMove: uciMove,
      shortMove: _shortMove,
      pv: _latestPv,
    );
  }

  double _normalizedScore(EngineAnalysisLine line) {
    final mate = line.mate;

    if (mate == null) {
      return (line.scoreCp ?? 0).toDouble();
    }

    final sign = mate == 0 ? 1 : mate.sign;
    final distancePenalty = mate.abs() * _analysisMateStepScore;
    return sign * (_analysisMateBaseScore - distancePenalty);
  }
}

