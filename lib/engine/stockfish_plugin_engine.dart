import 'dart:async';

import 'package:flutter_stockfish_plugin/stockfish.dart';
import 'package:flutter_stockfish_plugin/stockfish_state.dart';

import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class StockfishPluginEngine implements ChessEngine {
  StockfishPluginEngine();

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  Completer<String>? _bestMoveCompleter;

  bool _isRunning = false;
  bool _isStarting = false;

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() async {
    if (_isRunning || _isStarting) {
      return;
    }

    _isStarting = true;

    try {
      final stockfish = Stockfish();
      _stockfish = stockfish;

      _stdoutSubscription = stockfish.stdout.listen(_handleOutputLine);

      await _waitForEngineReady();

      _isRunning = true;

      _sendCommand('uci');
      await _waitForReadyOk();

      _sendCommand('setoption name Threads value 1');
      _sendCommand('setoption name Hash value 64');
      await _waitForReadyOk();

      _outputController.add('StockfishPluginEngine bereit.');
    } finally {
      _isStarting = false;
    }
  }

  @override
  Future<void> setSkillLevel(int level) async {
    await _ensureStarted();

    final safeLevel = level.clamp(0, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');
    await _waitForReadyOk();

    _outputController.add('Skill Level gesetzt: $safeLevel');
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

    return _searchBestMove(
      positionCommand: 'position fen $fen',
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

    _outputController.add(
      'MultiPV/Kandidaten sind im Stabilitäts-Fix noch deaktiviert.',
    );

    return const [];
  }

  @override
  Future<void> stop() async {
    final stockfish = _stockfish;

    if (stockfish == null) {
      return;
    }

    _sendCommand('quit');

    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;

    stockfish.dispose();

    _stockfish = null;
    _isRunning = false;
    _isStarting = false;

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete('(none)');
    }

    _bestMoveCompleter = null;

    if (!_outputController.isClosed) {
      _outputController.add('StockfishPluginEngine gestoppt.');
    }
  }

  Future<void> _ensureStarted() async {
    if (_isRunning) {
      return;
    }

    await start();
  }

  Future<void> _waitForEngineReady() async {
    final stockfish = _stockfish;

    if (stockfish == null) {
      throw StateError('Stockfish wurde nicht erstellt.');
    }

    final startedAt = DateTime.now();

    while (stockfish.state.value == StockfishState.starting) {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final elapsed = DateTime.now().difference(startedAt);

      if (elapsed > const Duration(seconds: 10)) {
        throw StateError('Stockfish Start-Timeout.');
      }
    }

    if (stockfish.state.value == StockfishState.error) {
      throw StateError('Stockfish konnte nicht gestartet werden.');
    }

    if (stockfish.state.value == StockfishState.disposed) {
      throw StateError('Stockfish wurde direkt beendet.');
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

      _outputController.add('UCI_Elo gesetzt: $safeElo');
      return;
    }

    final safeLevel = skillLevel.clamp(0, 20).toInt();

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');
    await _waitForReadyOk();

    _outputController.add('Skill Level gesetzt: $safeLevel');
  }

  Future<String> _searchBestMove({
    required String positionCommand,
    required int moveTimeMs,
  }) async {
    final existingCompleter = _bestMoveCompleter;

    if (existingCompleter != null && !existingCompleter.isCompleted) {
      existingCompleter.complete('(none)');
    }

    final completer = Completer<String>();
    _bestMoveCompleter = completer;

    _sendCommand(positionCommand);
    _sendCommand('go movetime $moveTimeMs');

    final bestMove = await completer.future.timeout(
      Duration(milliseconds: moveTimeMs + 8000),
      onTimeout: () {
        _bestMoveCompleter = null;
        _outputController.add('Stockfish Timeout: kein bestmove erhalten.');
        return '(none)';
      },
    );

    return bestMove;
  }

  Future<void> _waitForReadyOk() async {
    final completer = Completer<void>();
    late final StreamSubscription<String> subscription;

    subscription = output.listen((line) {
      if (line.trim() == 'readyok' && !completer.isCompleted) {
        completer.complete();
      }
    });

    _sendCommand('isready');

    try {
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  void _handleOutputLine(String line) {
    if (!_outputController.isClosed) {
      _outputController.add(line);
    }

    final trimmedLine = line.trim();

    if (!trimmedLine.startsWith('bestmove ')) {
      return;
    }

    final parts = trimmedLine.split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return;
    }

    final bestMove = parts[1];

    final completer = _bestMoveCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete(bestMove);
      _bestMoveCompleter = null;
    }
  }

  void _sendCommand(String command) {
    final stockfish = _stockfish;

    if (stockfish == null) {
      throw StateError('Stockfish läuft nicht. Command: $command');
    }

    stockfish.stdin = command;
  }
}
