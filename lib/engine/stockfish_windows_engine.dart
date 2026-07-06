import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/engine_analysis_line.dart';
import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class StockfishWindowsEngine implements ChessEngine {
  Process? _process;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<String>? _bestMoveCompleter;
  Completer<List<PersonaMoveCandidate>>? _candidateCompleter;
  Completer<List<EngineAnalysisLine>>? _analysisCompleter;

  final Map<int, PersonaMoveCandidate> _latestCandidatesByMultiPv = {};
  final Map<int, EngineAnalysisLine> _latestAnalysisLinesByMultiPv = {};

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _process != null;

  @override
  Future<void> start() async {
    if (_process != null) {
      return;
    }

    _process = await Process.start(
      r'engines\stockfish.exe',
      [],
      runInShell: true,
    );

    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleOutputLine);

    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          _outputController.add('ERROR: $line');
        });

    _uciOkCompleter = Completer<void>();

    _sendCommand('uci');

    await _uciOkCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw Exception('Stockfish hat nicht mit uciok geantwortet.');
      },
    );

    await _waitUntilReady();
  }

  @override
  Future<void> setSkillLevel(int level) async {
    final safeLevel = level.clamp(0, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');

    await _waitUntilReady();
  }

  Future<void> setUciElo(int elo) async {
    final safeElo = elo.clamp(1320, 3190).toInt();

    _sendCommand('setoption name UCI_LimitStrength value true');
    _sendCommand('setoption name UCI_Elo value $safeElo');

    await _waitUntilReady();
  }

  Future<void> setMultiPv(int value) async {
    final safeValue = value.clamp(1, 128).toInt();

    _sendCommand('setoption name MultiPV value $safeValue');

    await _waitUntilReady();
  }

  @override
  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    return getBestMoveFromFen(
      fen: 'startpos',
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
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
    if (_process == null) {
      await start();
    }

    if (useUciElo) {
      await setUciElo(uciElo);
    } else {
      await setSkillLevel(skillLevel);
    }

    await setMultiPv(1);

    _bestMoveCompleter = Completer<String>();
    _candidateCompleter = null;
    _analysisCompleter = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _setPosition(fen);
    _sendCommand('go movetime $moveTimeMs');

    return _bestMoveCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _bestMoveCompleter = null;
        throw Exception('Stockfish hat keinen bestmove geliefert.');
      },
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
    if (_process == null) {
      await start();
    }

    if (useUciElo) {
      await setUciElo(uciElo);
    } else {
      await setSkillLevel(skillLevel);
    }

    final safeCandidateCount = candidateCount.clamp(4, 128).toInt();

    await setMultiPv(safeCandidateCount);

    _bestMoveCompleter = null;
    _candidateCompleter = Completer<List<PersonaMoveCandidate>>();
    _analysisCompleter = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _setPosition(fen);
    _sendCommand('go movetime $moveTimeMs');

    return _candidateCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _candidateCompleter = null;
        _latestCandidatesByMultiPv.clear();
        throw Exception('Stockfish hat keine Kandidatenzüge geliefert.');
      },
    );
  }

  @override
  Future<List<EngineAnalysisLine>> analyzePositionFromFen({
    required String fen,
    int multiPv = 5,
    int depth = 20,
  }) async {
    if (_process == null) {
      await start();
    }

    final safeMultiPv = multiPv.clamp(1, 5).toInt();
    final safeDepth = depth.clamp(1, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value 20');
    await _waitUntilReady();

    await setMultiPv(safeMultiPv);

    _bestMoveCompleter = null;
    _candidateCompleter = null;
    _analysisCompleter = Completer<List<EngineAnalysisLine>>();
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _setPosition(fen);
    _sendCommand('go depth $safeDepth');

    return _analysisCompleter!.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _analysisCompleter = null;
        _latestAnalysisLinesByMultiPv.clear();
        throw Exception('Stockfish hat keine Analyse-Linien geliefert.');
      },
    );
  }

  void _setPosition(String fen) {
    if (fen == 'startpos') {
      _sendCommand('position startpos');
    } else {
      _sendCommand('position fen $fen');
    }
  }

  Future<void> _waitUntilReady() async {
    _readyOkCompleter = Completer<void>();

    _sendCommand('isready');

    await _readyOkCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw Exception('Stockfish hat nicht mit readyok geantwortet.');
      },
    );
  }

  void _handleOutputLine(String line) {
    _outputController.add(line);

    final trimmedLine = line.trim();

    if (trimmedLine == 'uciok') {
      if (_uciOkCompleter != null && !_uciOkCompleter!.isCompleted) {
        _uciOkCompleter!.complete();
      }
      _uciOkCompleter = null;
      return;
    }

    if (trimmedLine == 'readyok') {
      if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
        _readyOkCompleter!.complete();
      }
      _readyOkCompleter = null;
      return;
    }

    if (trimmedLine.startsWith('info ')) {
      _handleInfoLine(trimmedLine);
      return;
    }

    if (trimmedLine.startsWith('bestmove')) {
      _handleBestMoveLine(trimmedLine);
    }
  }

  void _handleInfoLine(String line) {
    if (_analysisCompleter != null) {
      final analysisLine = _parseAnalysisLineFromInfoLine(line);

      if (analysisLine != null && analysisLine.isValidMove) {
        final existing = _latestAnalysisLinesByMultiPv[analysisLine.rank];

        if (existing == null || analysisLine.depth >= existing.depth) {
          _latestAnalysisLinesByMultiPv[analysisLine.rank] = analysisLine;
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
        scoreCp = scoreValue;
      } else if (scoreType == 'mate') {
        mate = scoreValue;
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

      _analysisCompleter!.complete(List.unmodifiable(lines.take(5)));
      _analysisCompleter = null;
      _latestAnalysisLinesByMultiPv.clear();
    }
  }

  void _sendCommand(String command) {
    _process?.stdin.writeln(command);
  }

  void _completePendingSearchesOnStop() {
    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete('(none)');
    }

    if (_candidateCompleter != null && !_candidateCompleter!.isCompleted) {
      _candidateCompleter!.complete(const []);
    }

    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(const []);
    }

    _bestMoveCompleter = null;
    _candidateCompleter = null;
    _analysisCompleter = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();
  }

  @override
  Future<void> stop() async {
    if (_process == null) {
      return;
    }

    _completePendingSearchesOnStop();
    _sendCommand('quit');

    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();

    _process?.kill();
    _process = null;
  }

  Future<void> dispose() async {
    await stop();
    await _outputController.close();
  }
}
