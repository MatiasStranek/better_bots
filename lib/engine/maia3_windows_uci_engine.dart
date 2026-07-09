import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/engine_analysis_line.dart';
import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class Maia3WindowsUciEngine implements ChessEngine {
  Maia3WindowsUciEngine({
    this.executablePath =
        r'C:\dev\essentials\maia3\.venv\Scripts\maia3-uci.exe',
    this.workingDirectory = r'C:\dev\essentials\maia3',
    this.model = 'maia3-5m',
    this.device = 'cpu',
    this.useUciHistory = true,
  });

  final String executablePath;
  final String workingDirectory;
  final String model;
  final String device;
  final bool useUciHistory;

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
  EngineAnalysisUpdate? _analysisUpdateCallback;

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

    final args = <String>[
      '--model',
      model,
      if (useUciHistory) '--use-uci-history',
      '--device',
      device,
      '--no-use-amp',
    ];

    _addOutput('Maia3 Windows startet: $executablePath ${args.join(' ')}');

    _process = await Process.start(
      executablePath,
      args,
      workingDirectory: workingDirectory,
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
      _addOutput('MAIA STDERR: $line');
    });

    _uciOkCompleter = Completer<void>();
    _sendCommand('uci');

    await _uciOkCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Maia3 hat nicht mit uciok geantwortet.');
      },
    );

    await _waitUntilReady(timeout: const Duration(seconds: 120));

    _addOutput('Maia3 Windows bereit.');
  }

  @override
  Future<void> setSkillLevel(int level) async {
    // Maia3 nutzt Rating-Conditioning über Elo statt Stockfish Skill-Level.
  }

  Future<String> getBestMoveFromGame({
    required String startFen,
    required List<String> moves,
    required int elo,
    double temperature = 1.0,
    double topP = 0.95,
  }) async {
    await _ensureStarted();
    await _configureMaia(
      elo: elo,
      temperature: temperature,
      topP: topP,
      multiPv: 5,
    );

    return _searchBestMove(
      positionCommand: _positionCommandFromGame(
        startFen: startFen,
        moves: moves,
      ),
    );
  }

  @override
  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    await _ensureStarted();
    await _configureMaia(elo: uciElo, multiPv: 5);

    return _searchBestMove(positionCommand: 'position startpos');
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
    await _configureMaia(elo: uciElo, multiPv: 5);

    return _searchBestMove(
      positionCommand: _positionCommandFromFen(fen),
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

    final safeCandidateCount = candidateCount.clamp(1, 20).toInt();

    await _configureMaia(elo: uciElo, multiPv: safeCandidateCount);

    _bestMoveCompleter = null;
    _candidateCompleter = Completer<List<PersonaMoveCandidate>>();
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(_positionCommandFromFen(fen));
    _sendCommand('go nodes 1');

    return _candidateCompleter!.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _candidateCompleter = null;
        throw Exception('Maia3 hat keine Kandidaten geliefert.');
      },
    );
  }

  @override
  Future<List<EngineAnalysisLine>> analyzePositionFromFen({
    required String fen,
    int multiPv = 5,
    int depth = 20,
    EngineAnalysisUpdate? onUpdate,
  }) async {
    await _ensureStarted();

    final safeMultiPv = multiPv.clamp(1, 20).toInt();

    await _configureMaia(elo: 1500, multiPv: safeMultiPv);

    _bestMoveCompleter = null;
    _candidateCompleter = null;
    _analysisCompleter = Completer<List<EngineAnalysisLine>>();
    _analysisUpdateCallback = onUpdate;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(_positionCommandFromFen(fen));
    _sendCommand('go nodes 1');

    return _analysisCompleter!.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _analysisCompleter = null;
        _analysisUpdateCallback = null;
        throw Exception('Maia3 hat keine Analyse-Linien geliefert.');
      },
    );
  }

  Future<void> _configureMaia({
    required int elo,
    double temperature = 1.0,
    double topP = 0.95,
    int multiPv = 5,
  }) async {
    final safeElo = elo.clamp(0, 5000).toInt();
    final safeMultiPv = multiPv.clamp(1, 20).toInt();

    _sendCommand('setoption name Elo value $safeElo');
    _sendCommand('setoption name SelfElo value $safeElo');
    _sendCommand('setoption name OppoElo value $safeElo');
    _sendCommand('setoption name Temperature value ${temperature.toStringAsFixed(3)}');
    _sendCommand('setoption name TopP value ${topP.toStringAsFixed(3)}');
    _sendCommand('setoption name MultiPV value $safeMultiPv');

    await _waitUntilReady(timeout: const Duration(seconds: 120));
  }

  Future<String> _searchBestMove({required String positionCommand}) {
    _bestMoveCompleter = Completer<String>();
    _candidateCompleter = null;
    _analysisCompleter = null;
    _analysisUpdateCallback = null;
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();

    _sendCommand(positionCommand);
    _sendCommand('go nodes 1');

    return _bestMoveCompleter!.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _bestMoveCompleter = null;
        throw Exception('Maia3 hat keinen bestmove geliefert.');
      },
    );
  }

  String _positionCommandFromGame({
    required String startFen,
    required List<String> moves,
  }) {
    final cleanMoves = moves
        .map((move) => move.trim())
        .where((move) => move.length >= 4)
        .join(' ');

    final isStartPosition = startFen.trim() ==
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    final baseCommand = isStartPosition
        ? 'position startpos'
        : 'position fen ${startFen.trim()}';

    if (cleanMoves.isEmpty) {
      return baseCommand;
    }

    return '$baseCommand moves $cleanMoves';
  }

  String _positionCommandFromFen(String fen) {
    final normalizedFen = fen.trim();

    if (normalizedFen.isEmpty || normalizedFen == 'startpos') {
      return 'position startpos';
    }

    return 'position fen $normalizedFen';
  }

  void _handleOutputLine(String line) {
    _addOutput(line);

    if (line == 'uciok') {
      final completer = _uciOkCompleter;

      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }

      return;
    }

    if (line == 'readyok') {
      final completer = _readyOkCompleter;

      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }

      return;
    }

    if (line.startsWith('info ')) {
      _handleInfoLine(line);
      return;
    }

    if (line.startsWith('bestmove ')) {
      _handleBestMoveLine(line);
    }
  }

  void _handleInfoLine(String line) {
    final candidate = _candidateFromInfoLine(line);
    final analysisLine = _analysisLineFromInfoLine(line);

    if (candidate != null) {
      _latestCandidatesByMultiPv[candidate.multiPv] = candidate;
    }

    if (analysisLine != null) {
      _latestAnalysisLinesByMultiPv[analysisLine.rank] = analysisLine;

      final callback = _analysisUpdateCallback;
      if (callback != null) {
        final lines = _latestAnalysisLinesByMultiPv.values.toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

        callback(List<EngineAnalysisLine>.unmodifiable(lines));
      }
    }
  }

  PersonaMoveCandidate? _candidateFromInfoLine(String line) {
    final analysisLine = _analysisLineFromInfoLine(line);

    if (analysisLine == null) {
      return null;
    }

    return PersonaMoveCandidate(
      uciMove: analysisLine.uciMove,
      multiPv: analysisLine.rank,
      scoreCp: analysisLine.scoreCp ?? 0,
      depth: analysisLine.depth,
      pv: analysisLine.pv,
    );
  }

  EngineAnalysisLine? _analysisLineFromInfoLine(String line) {
    final parts = line.split(RegExp(r'\s+'));

    final pvIndex = parts.indexOf('pv');
    if (pvIndex < 0 || pvIndex + 1 >= parts.length) {
      return null;
    }

    final pv = parts.sublist(pvIndex + 1);
    if (pv.isEmpty) {
      return null;
    }

    var depth = 1;
    final depthIndex = parts.indexOf('depth');
    if (depthIndex >= 0 && depthIndex + 1 < parts.length) {
      depth = int.tryParse(parts[depthIndex + 1]) ?? 1;
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
        ..sort((a, b) => a.multiPv.compareTo(b.multiPv));

      if (candidates.isEmpty && bestMove != '(none)') {
        candidates.add(
          PersonaMoveCandidate(
            uciMove: bestMove,
            multiPv: 1,
            scoreCp: 0,
            depth: 1,
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
            depth: 1,
            scoreCp: 0,
            uciMove: bestMove,
            pv: [bestMove],
          ),
        );
      }

      final result = List<EngineAnalysisLine>.unmodifiable(lines);
      _analysisCompleter!.complete(result);
      _analysisCompleter = null;
      _analysisUpdateCallback = null;
      _latestAnalysisLinesByMultiPv.clear();
    }
  }

  Future<void> _ensureStarted() async {
    if (_process == null) {
      await start();
    }
  }

  Future<void> _waitUntilReady({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _readyOkCompleter = Completer<void>();
    _sendCommand('isready');

    await _readyOkCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        _readyOkCompleter = null;
        throw Exception('Maia3 hat nicht mit readyok geantwortet.');
      },
    );
  }

  void _sendCommand(String command) {
    _addOutput('> $command');
    _process?.stdin.writeln(command);
  }

  void _addOutput(String line) {
    if (!_outputController.isClosed) {
      _outputController.add(line);
    }
  }

  @override
  Future<void> cancelSearch() async {
    _completePendingSearchesOnStop();

    if (_process == null) {
      return;
    }

    _sendCommand('stop');
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

  void _completePendingSearchesOnStop() {
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
    _latestCandidatesByMultiPv.clear();
    _latestAnalysisLinesByMultiPv.clear();
  }

  Future<void> dispose() async {
    await stop();

    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }
}
