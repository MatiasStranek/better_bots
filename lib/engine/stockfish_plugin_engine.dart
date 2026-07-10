import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';

import '../models/engine_analysis_line.dart';
import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class StockfishPluginEngine implements ChessEngine {
  StockfishPluginEngine();

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;

  Future<void>? _startFuture;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<String>? _bestMoveCompleter;
  Completer<List<PersonaMoveCandidate>>? _candidateCompleter;
  Completer<List<EngineAnalysisLine>>? _analysisCompleter;
  EngineAnalysisUpdate? _analysisUpdateCallback;

  static const int _analysisLiveUpdateMinDepth = 1;

  int _analysisRequestedMultiPv = 5;
  int _lastEmittedAnalysisDepth = 0;

  /// Stockfish liefert UCI-Analyse-Scores aus Sicht der Seite am Zug.
  /// Für die UI normalisieren wir Analysewerte auf Weiß-Sicht:
  /// positiv = Weiß steht besser, negativ = Schwarz steht besser.
  int _analysisScoreSign = 1;

  final Map<int, PersonaMoveCandidate> _latestCandidatesByMultiPv = {};
  final Map<int, EngineAnalysisLine> _latestAnalysisLinesByMultiPv = {};

  bool _isRunning = false;
  bool _isStarting = false;
  int _searchCancelGeneration = 0;

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() {
    if (_isRunning) {
      return Future<void>.value();
    }

    final existingStartFuture = _startFuture;
    if (existingStartFuture != null) {
      return existingStartFuture;
    }

    final startFuture = _startInternal();
    _startFuture = startFuture;
    return startFuture;
  }

  Future<void> _startInternal() async {
    _isStarting = true;

    try {
      _addOutput('StockfishPluginEngine startet mit multistockfish...');

      final stockfish = Stockfish.instance;
      _stockfish = stockfish;

      _stdoutSubscription = stockfish.stdout.listen(
        _handleRawOutput,
        onError: (error) {
          _addOutput('ANDROID STOCKFISH STDOUT ERROR: $error');
        },
        onDone: () {
          _addOutput('ANDROID STOCKFISH STDOUT CLOSED');
        },
      );

      await _startStockfishInstance(stockfish);

      _isRunning = true;

      await _waitForUciOk();
      await _waitForReadyOk();

      _sendCommand('setoption name Threads value 1');
      _sendCommand('setoption name Hash value 64');
      await _waitForReadyOk();

      _addOutput('StockfishPluginEngine bereit.');
    } catch (error, stackTrace) {
      _addOutput('StockfishPluginEngine Startfehler: $error');

      debugPrintStack(
        label: 'StockfishPluginEngine Startfehler StackTrace',
        stackTrace: stackTrace,
      );

      await stop();
      rethrow;
    } finally {
      _isStarting = false;
      _startFuture = null;
    }
  }

  Future<void> _startStockfishInstance(Stockfish stockfish) async {
    try {
      await stockfish.start();
    } on StateError catch (error) {
      _addOutput(
        'Stockfish start() meldet StateError. Versuche quit() und Neustart: $error',
      );

      await stockfish.quit();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await stockfish.start();
    }

    _addOutput('Android Stockfish State: ${stockfish.state.value}');

    if (stockfish.state.value != StockfishState.ready) {
      throw StateError(
        'Stockfish ist nach start() nicht bereit. State: ${stockfish.state.value}',
      );
    }
  }

  @override
  Future<void> setSkillLevel(int level) async {
    await _ensureStarted();

    final safeLevel = level.clamp(0, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');
    await _waitForReadyOk();

    _addOutput('Skill Level gesetzt: $safeLevel');
  }

  Future<void> setUciElo(int elo) async {
    await _ensureStarted();

    final safeElo = elo.clamp(1320, 3190).toInt();

    _sendCommand('setoption name UCI_LimitStrength value true');
    _sendCommand('setoption name UCI_Elo value $safeElo');
    await _waitForReadyOk();

    _addOutput('UCI_Elo gesetzt: $safeElo');
  }

  Future<void> setMultiPv(int value) async {
    await _ensureStarted();

    final safeValue = value.clamp(1, 128).toInt();

    _sendCommand('setoption name MultiPV value $safeValue');
    await _waitForReadyOk();

    _addOutput('MultiPV gesetzt: $safeValue');
  }

  @override
  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    await _ensureStarted();

    await _configureStrength(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    await setMultiPv(1);

    return _searchBestMove(
      positionCommand: 'position startpos',
      moveTimeMs: moveTimeMs,
    );
  }

  @override
  Future<String> getBestMoveFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    await _ensureStarted();

    await _configureStrength(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    await setMultiPv(1);

    return _searchBestMove(
      positionCommand: _positionCommandFromFen(fen),
      moveTimeMs: moveTimeMs,
    );
  }

  @override
  Future<List<PersonaMoveCandidate>> getMoveCandidatesFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    required int candidateCount,
    int moveTimeMs = 800,
  }) async {
    await _ensureStarted();

    await _configureStrength(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    final safeCandidateCount = candidateCount.clamp(4, 128).toInt();
    await setMultiPv(safeCandidateCount);

    return _searchMoveCandidates(
      positionCommand: _positionCommandFromFen(fen),
      moveTimeMs: moveTimeMs,
    );
  }

  @override
  Future<List<EngineAnalysisLine>> analyzePositionFromFen({
    required String fen,
    int multiPv = 5,
    int depth = 20,
    EngineAnalysisUpdate? onUpdate,
  }) async {
    final cancelGeneration = _searchCancelGeneration;

    await _ensureStarted();

    if (cancelGeneration != _searchCancelGeneration) {
      return const <EngineAnalysisLine>[];
    }

    final safeMultiPv = multiPv.clamp(1, 5).toInt();
    final safeDepth = depth.clamp(1, 20).toInt();
    _analysisScoreSign = _analysisScoreSignFromFen(fen);

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value 20');
    await _waitForReadyOk();

    if (cancelGeneration != _searchCancelGeneration) {
      return const <EngineAnalysisLine>[];
    }

    await setMultiPv(safeMultiPv);

    if (cancelGeneration != _searchCancelGeneration) {
      return const <EngineAnalysisLine>[];
    }

    return _searchAnalysisLines(
      positionCommand: _positionCommandFromFen(fen),
      depth: safeDepth,
      requestedMultiPv: safeMultiPv,
      onUpdate: onUpdate,
    );
  }

  @override
  Future<void> cancelSearch() async {
    _searchCancelGeneration++;
    _cancelPendingSearches();

    final stockfish = _stockfish;
    if (stockfish == null || !_isRunning) {
      _addOutput('StockfishPluginEngine Suche abgebrochen, Engine läuft nicht.');
      return;
    }

    try {
      _sendCommand('stop');
    } catch (error) {
      _addOutput('StockfishPluginEngine Suchabbruch fehlgeschlagen: $error');
    }
  }

  @override
  Future<void> stop() async {
    _searchCancelGeneration++;
    final stockfish = _stockfish;

    if (stockfish == null) {
      _isRunning = false;
      _isStarting = false;
      _startFuture = null;
      _completePendingWaitersOnStop();
      return;
    }

    try {
      await stockfish.quit();
    } catch (_) {
      // Beim Stoppen bewusst ignorieren.
    }

    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;

    _stockfish = null;
    _isRunning = false;
    _isStarting = false;
    _startFuture = null;

    _completePendingWaitersOnStop();

    _addOutput('StockfishPluginEngine gestoppt.');
  }

  Future<void> dispose() async {
    await stop();

    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }

  Future<void> _ensureStarted() async {
    if (_isRunning) {
      return;
    }

    await start();
  }

  Future<void> _waitForUciOk() async {
    final completer = Completer<void>();
    _uciOkCompleter = completer;

    _sendCommand('uci');

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw StateError(
            'Android Stockfish hat nicht mit uciok geantwortet.',
          );
        },
      );
    } finally {
      if (identical(_uciOkCompleter, completer)) {
        _uciOkCompleter = null;
      }
    }
  }

  Future<void> _waitForReadyOk() async {
    final completer = Completer<void>();
    _readyOkCompleter = completer;

    _sendCommand('isready');

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw StateError(
            'Android Stockfish hat nicht mit readyok geantwortet.',
          );
        },
      );
    } finally {
      if (identical(_readyOkCompleter, completer)) {
        _readyOkCompleter = null;
      }
    }
  }

  Future<void> _configureStrength({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) async {
    if (useUciElo) {
      final safeElo = uciElo.clamp(1320, 3190).toInt();

      _sendCommand('setoption name UCI_LimitStrength value true');
      _sendCommand('setoption name UCI_Elo value $safeElo');
      await _waitForReadyOk();

      _addOutput('UCI_Elo gesetzt: $safeElo');
      return;
    }

    final safeLevel = skillLevel.clamp(0, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');
    await _waitForReadyOk();

    _addOutput('Skill Level gesetzt: $safeLevel');
  }

  Future<String> _searchBestMove({
    required String positionCommand,
    required int moveTimeMs,
  }) async {
    _cancelPendingSearches();

    final completer = Completer<String>();
    _bestMoveCompleter = completer;
    _candidateCompleter = null;
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _analysisRequestedMultiPv = 5;
    _lastEmittedAnalysisDepth = 0;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(positionCommand);
    _sendCommand('go movetime $moveTimeMs');

    final bestMove = await completer.future.timeout(
      Duration(milliseconds: moveTimeMs + 10000),
      onTimeout: () {
        if (identical(_bestMoveCompleter, completer)) {
          _bestMoveCompleter = null;
        }

        _addOutput('Stockfish Timeout: kein bestmove erhalten.');
        return '(none)';
      },
    );

    _addOutput('Stockfish bestmove zurückgegeben: $bestMove');
    return bestMove;
  }

  Future<List<PersonaMoveCandidate>> _searchMoveCandidates({
    required String positionCommand,
    required int moveTimeMs,
  }) async {
    _cancelPendingSearches();

    final completer = Completer<List<PersonaMoveCandidate>>();
    _candidateCompleter = completer;
    _bestMoveCompleter = null;
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _analysisRequestedMultiPv = 5;
    _lastEmittedAnalysisDepth = 0;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(positionCommand);
    _sendCommand('go movetime $moveTimeMs');

    final candidates = await completer.future.timeout(
      Duration(milliseconds: moveTimeMs + 10000),
      onTimeout: () {
        if (identical(_candidateCompleter, completer)) {
          _candidateCompleter = null;
        }

        _latestCandidatesByMultiPv.clear();
        _addOutput('Stockfish Timeout: keine Kandidatenzüge erhalten.');
        return const <PersonaMoveCandidate>[];
      },
    );

    _addOutput('Stockfish Kandidaten zurückgegeben: ${candidates.length}');
    return candidates;
  }

  Future<List<EngineAnalysisLine>> _searchAnalysisLines({
    required String positionCommand,
    required int depth,
    required int requestedMultiPv,
    EngineAnalysisUpdate? onUpdate,
  }) async {
    _cancelPendingSearches();

    final completer = Completer<List<EngineAnalysisLine>>();
    _analysisCompleter = completer;
    _analysisUpdateCallback = onUpdate;
    _analysisRequestedMultiPv = requestedMultiPv;
    _lastEmittedAnalysisDepth = 0;
    _candidateCompleter = null;
    _bestMoveCompleter = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(positionCommand);
    _sendCommand('go depth $depth');

    final lines = await completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        if (identical(_analysisCompleter, completer)) {
          _analysisCompleter = null;
        }

        _analysisUpdateCallback = null;
        _latestAnalysisLinesByMultiPv.clear();
        _addOutput('Stockfish Timeout: keine Analyse-Linien erhalten.');
        return const <EngineAnalysisLine>[];
      },
    );

    _addOutput('Stockfish Analyse-Linien zurückgegeben: ${lines.length}');
    return lines;
  }

  void _cancelPendingSearches() {
    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete('(none)');
    }

    if (_candidateCompleter != null && !_candidateCompleter!.isCompleted) {
      _candidateCompleter!.complete(const []);
    }

    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(const <EngineAnalysisLine>[]);
    }

    _bestMoveCompleter = null;
    _candidateCompleter = null;
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _analysisRequestedMultiPv = 5;
    _lastEmittedAnalysisDepth = 0;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();
  }

  void _completePendingWaitersOnStop() {
    if (_uciOkCompleter != null && !_uciOkCompleter!.isCompleted) {
      _uciOkCompleter!.complete();
    }

    if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
      _readyOkCompleter!.complete();
    }

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete('(none)');
    }

    if (_candidateCompleter != null && !_candidateCompleter!.isCompleted) {
      _candidateCompleter!.complete(const []);
    }

    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(const <EngineAnalysisLine>[]);
    }

    _uciOkCompleter = null;
    _readyOkCompleter = null;
    _analysisUpdateCallback = null;
    _bestMoveCompleter = null;
    _candidateCompleter = null;
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _analysisRequestedMultiPv = 5;
    _lastEmittedAnalysisDepth = 0;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();
  }

  String _positionCommandFromFen(String fen) {
    final trimmedFen = fen.trim();

    if (trimmedFen == 'startpos') {
      return 'position startpos';
    }

    return 'position fen $trimmedFen';
  }

  void _handleRawOutput(String rawOutput) {
    final normalizedOutput = rawOutput
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final lines = normalizedOutput.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        continue;
      }

      _handleOutputLine(trimmedLine);
    }
  }

  void _handleOutputLine(String line) {
    _addOutput('ANDROID STOCKFISH << $line');

    if (line == 'uciok') {
      if (_uciOkCompleter != null && !_uciOkCompleter!.isCompleted) {
        _uciOkCompleter!.complete();
      }

      _uciOkCompleter = null;
      return;
    }

    if (line == 'readyok') {
      if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
        _readyOkCompleter!.complete();
      }

      _readyOkCompleter = null;
      return;
    }

    if (line.startsWith('info ')) {
      _handleInfoLine(line);
      return;
    }

    if (line.startsWith('bestmove')) {
      _handleBestMoveLine(line);
    }
  }

  void _handleInfoLine(String line) {
    if (_analysisCompleter != null) {
      final analysisLine = _parseAnalysisLineFromInfoLine(line);

      if (analysisLine != null && analysisLine.isValidMove) {
        final existing = _latestAnalysisLinesByMultiPv[analysisLine.rank];

        if (existing == null || analysisLine.depth >= existing.depth) {
          _latestAnalysisLinesByMultiPv[analysisLine.rank] = analysisLine;
          _emitAnalysisUpdateIfWholeDepthReady();
        }
      }
    }

    if (_candidateCompleter == null) {
      return;
    }

    final candidate = _parseCandidateFromInfoLine(line);

    if (candidate == null || !candidate.isValidMove) {
      return;
    }

    final existing = _latestCandidatesByMultiPv[candidate.multiPv];

    if (existing == null || candidate.depth >= existing.depth) {
      _latestCandidatesByMultiPv[candidate.multiPv] = candidate;
    }
  }

  PersonaMoveCandidate? _parseCandidateFromInfoLine(String line) {
    final parts = line.split(RegExp(r'\s+'));

    final pvIndex = parts.indexOf('pv');

    if (pvIndex < 0 || pvIndex + 1 >= parts.length) {
      return null;
    }

    final pv = parts.sublist(pvIndex + 1);

    if (pv.isEmpty) {
      return null;
    }

    final uciMove = pv.first;

    var depth = 0;
    final depthIndex = parts.indexOf('depth');
    if (depthIndex >= 0 && depthIndex + 1 < parts.length) {
      depth = int.tryParse(parts[depthIndex + 1]) ?? 0;
    }

    var multiPv = 1;
    final multiPvIndex = parts.indexOf('multipv');
    if (multiPvIndex >= 0 && multiPvIndex + 1 < parts.length) {
      multiPv = int.tryParse(parts[multiPvIndex + 1]) ?? 1;
    }

    var scoreCp = 0;
    final scoreIndex = parts.indexOf('score');
    if (scoreIndex >= 0 && scoreIndex + 2 < parts.length) {
      final scoreType = parts[scoreIndex + 1];
      final scoreValue = int.tryParse(parts[scoreIndex + 2]) ?? 0;

      if (scoreType == 'cp') {
        scoreCp = scoreValue;
      } else if (scoreType == 'mate') {
        scoreCp = _mateScoreToCentipawns(scoreValue);
      }
    }

    return PersonaMoveCandidate(
      uciMove: uciMove,
      multiPv: multiPv,
      scoreCp: scoreCp,
      depth: depth,
      pv: pv,
    );
  }

  EngineAnalysisLine? _parseAnalysisLineFromInfoLine(String line) {
    final parts = line.split(RegExp(r'\s+'));

    final pvIndex = parts.indexOf('pv');

    if (pvIndex < 0 || pvIndex + 1 >= parts.length) {
      return null;
    }

    final pv = parts.sublist(pvIndex + 1);

    if (pv.isEmpty) {
      return null;
    }

    var depth = 0;
    final depthIndex = parts.indexOf('depth');
    if (depthIndex >= 0 && depthIndex + 1 < parts.length) {
      depth = int.tryParse(parts[depthIndex + 1]) ?? 0;
    }

    var multiPv = 1;
    final multiPvIndex = parts.indexOf('multipv');
    if (multiPvIndex >= 0 && multiPvIndex + 1 < parts.length) {
      multiPv = int.tryParse(parts[multiPvIndex + 1]) ?? 1;
    }

    int? scoreCp;
    int? mate;
    final scoreIndex = parts.indexOf('score');
    if (scoreIndex >= 0 && scoreIndex + 2 < parts.length) {
      final scoreType = parts[scoreIndex + 1];
      final scoreValue = int.tryParse(parts[scoreIndex + 2]);

      if (scoreType == 'cp') {
        scoreCp = _analysisScoreCpFromEngine(scoreValue);
      } else if (scoreType == 'mate') {
        mate = _analysisMateFromEngine(scoreValue);
      }
    }

    return EngineAnalysisLine(
      rank: multiPv,
      depth: depth,
      scoreCp: scoreCp,
      mate: mate,
      uciMove: pv.first,
      pv: pv,
    );
  }


  int _analysisScoreSignFromFen(String fen) {
    final trimmedFen = fen.trim();

    if (trimmedFen.isEmpty || trimmedFen == 'startpos') {
      return 1;
    }

    final parts = trimmedFen.split(RegExp(r'\s+'));

    if (parts.length >= 2 && parts[1] == 'b') {
      return -1;
    }

    return 1;
  }

  int? _analysisScoreCpFromEngine(int? scoreCp) {
    if (scoreCp == null) {
      return null;
    }

    return scoreCp * _analysisScoreSign;
  }

  int? _analysisMateFromEngine(int? mate) {
    if (mate == null) {
      return null;
    }

    return mate * _analysisScoreSign;
  }

  int _mateScoreToCentipawns(int mateScore) {
    if (mateScore > 0) {
      return 100000 - mateScore.abs();
    }

    if (mateScore < 0) {
      return -100000 + mateScore.abs();
    }

    return 0;
  }

  void _handleBestMoveLine(String line) {
    final parts = line.split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return;
    }

    final bestMove = parts[1];

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete(bestMove);
      _bestMoveCompleter = null;
    }

    if (_candidateCompleter != null && !_candidateCompleter!.isCompleted) {
      final candidates = _latestCandidatesByMultiPv.values.toList()
        ..sort((a, b) {
          final byMultiPv = a.multiPv.compareTo(b.multiPv);

          if (byMultiPv != 0) {
            return byMultiPv;
          }

          return b.scoreCp.compareTo(a.scoreCp);
        });

      if (candidates.isEmpty && bestMove != '(none)') {
        candidates.add(
          PersonaMoveCandidate(
            uciMove: bestMove,
            multiPv: 1,
            scoreCp: 0,
            depth: 0,
            pv: [bestMove],
          ),
        );
      }

      _candidateCompleter!.complete(candidates);
      _candidateCompleter = null;
      _latestCandidatesByMultiPv.clear();
    }

    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      final lines = _latestAnalysisLinesByMultiPv.values.toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

      if (lines.isEmpty && bestMove != '(none)') {
        lines.add(
          EngineAnalysisLine(
            rank: 1,
            depth: 0,
            scoreCp: 0,
            uciMove: bestMove,
            pv: [bestMove],
          ),
        );
      }

      final completedLines = List<EngineAnalysisLine>.unmodifiable(lines.take(5));
      _analysisCompleter!.complete(completedLines);
      _analysisCompleter = null;
      _analysisUpdateCallback = null;
      _latestAnalysisLinesByMultiPv.clear();
    }
  }


  void _emitAnalysisUpdateIfWholeDepthReady() {
    final callback = _analysisUpdateCallback;

    if (callback == null) {
      return;
    }

    final lines = _latestAnalysisLinesByMultiPv.values.toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    if (lines.length < _analysisRequestedMultiPv) {
      return;
    }

    var completedDepth = lines.first.depth;

    for (final line in lines.take(_analysisRequestedMultiPv)) {
      if (line.depth < completedDepth) {
        completedDepth = line.depth;
      }
    }

    if (completedDepth < _analysisLiveUpdateMinDepth ||
        completedDepth <= _lastEmittedAnalysisDepth) {
      return;
    }

    _lastEmittedAnalysisDepth = completedDepth;

    try {
      callback(
      List<EngineAnalysisLine>.unmodifiable(lines.take(_analysisRequestedMultiPv)),
    );
    } catch (error) {
      _addOutput('Analyse-Update-Callback fehlgeschlagen: $error');
    }
  }

  void _sendCommand(String command) {
    final stockfish = _stockfish;

    if (stockfish == null) {
      throw StateError('Stockfish läuft nicht. Command: $command');
    }

    _addOutput('ANDROID STOCKFISH >> $command');

    stockfish.stdin = command;
  }

  void _addOutput(String line) {
    debugPrint(line);

    if (_outputController.isClosed) {
      return;
    }

    _outputController.add(line);
  }
}
