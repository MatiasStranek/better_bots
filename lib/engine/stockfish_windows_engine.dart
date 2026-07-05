import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'chess_engine.dart';

class StockfishWindowsEngine implements ChessEngine {
  Process? _process;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<String>? _bestMoveCompleter;

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
    final safeLevel = level.clamp(0, 20);

    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('setoption name Skill Level value $safeLevel');

    await _waitUntilReady();
  }

  Future<void> setUciElo(int elo) async {
    final safeElo = elo.clamp(1320, 3190);

    _sendCommand('setoption name UCI_LimitStrength value true');
    _sendCommand('setoption name UCI_Elo value $safeElo');

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

    _bestMoveCompleter = Completer<String>();

    if (fen == 'startpos') {
      _sendCommand('position startpos');
    } else {
      _sendCommand('position fen $fen');
    }

    _sendCommand('go movetime $moveTimeMs');

    return _bestMoveCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Stockfish hat keinen bestmove geliefert.');
      },
    );
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

    if (trimmedLine.startsWith('bestmove')) {
      final parts = trimmedLine.split(' ');

      if (parts.length >= 2) {
        final bestMove = parts[1];

        if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
          _bestMoveCompleter!.complete(bestMove);
        }

        _bestMoveCompleter = null;
      }
    }
  }

  void _sendCommand(String command) {
    _process?.stdin.writeln(command);
  }

  @override
  Future<void> stop() async {
    if (_process == null) {
      return;
    }

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
