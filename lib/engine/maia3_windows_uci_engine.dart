import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/engine_analysis_line.dart';
import 'chess_engine.dart';
import 'maia3_android_position_encoder.dart';
import 'personality/persona_move_candidate.dart';

/// Native Maia3-5M inference for Windows.
///
/// The historical class name is kept so existing controller type checks do not
/// have to change. This implementation no longer starts the external Python
/// UCI process. It loads the bundled ONNX model directly through ONNX Runtime.
class Maia3WindowsUciEngine implements ChessEngine {
  Maia3WindowsUciEngine({
    this.modelRelativePath = const <String>[
      'engines',
      'maia3',
      'maia3-5m.onnx',
    ],
  });

  final List<String> modelRelativePath;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final Maia3AndroidPositionEncoder _encoder =
      const Maia3AndroidPositionEncoder();
  final Random _random = Random();
  static const MethodChannel _channel = MethodChannel(
    'better_bots/maia3_windows_onnx',
  );

  bool _isStarted = false;
  Future<void>? _startFuture;
  Future<void> _inferenceTail = Future<void>.value();
  int _searchGeneration = 0;

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _isStarted;

  @override
  Future<void> start() async {
    if (_isStarted) {
      return;
    }

    final pendingStart = _startFuture;
    if (pendingStart != null) {
      await pendingStart;
      return;
    }

    final startFuture = _startInternal();
    _startFuture = startFuture;

    try {
      await startFuture;
    } finally {
      if (identical(_startFuture, startFuture)) {
        _startFuture = null;
      }
    }
  }

  Future<void> _startInternal() async {
    final message = await _channel.invokeMethod<String>('initialize');
    _isStarted = true;
    _addOutput(message ?? 'Maia3 Windows ONNX bereit.');
  }

  @override
  Future<void> setSkillLevel(int level) async {
    // Maia3 nutzt Elo-Conditioning statt eines Stockfish-Skill-Levels.
  }

  Future<String> getBestMoveFromGame({
    required String startFen,
    required List<String> moves,
    required String fen,
    required int elo,
    double temperature = 1.0,
    double topP = 0.95,
  }) async {
    await _ensureStarted();

    final requestGeneration = ++_searchGeneration;
    final safeElo = elo.clamp(0, 5000).toInt();

    _addOutput(
      'Maia3 Windows kodiert Position: Elo $safeElo, '
      '${moves.length} Halbzüge History.',
    );

    final encoded = _encoder.encode(
      startFen: startFen,
      moves: moves,
      fen: fen,
    );

    final logits = await _runSerial<List<double>>(
      () => _runPolicyInference(
        tokens: encoded.tokens,
        elo: safeElo,
      ),
    );

    if (requestGeneration != _searchGeneration) {
      _addOutput('Maia3 Windows: veraltetes Ergebnis verworfen.');
      return '(none)';
    }

    final candidates = _buildLegalCandidates(
      logits: logits,
      legalMoveIndices: encoded.legalMoveIndices,
      legalMoveUcis: encoded.legalMoveUcis,
    );

    final selected = _selectMove(
      candidates: candidates,
      temperature: temperature,
      topP: topP,
    );

    final topDebug = (List<_MaiaPolicyCandidate>.of(candidates)
          ..sort((a, b) => b.logit.compareTo(a.logit)))
        .take(5)
        .map((candidate) {
          return '${candidate.uci}:${candidate.logit.toStringAsFixed(3)}';
        })
        .join(', ');

    _addOutput(
      'Maia3 Windows bestmove ${selected.uci} | '
      'legal=${candidates.length}, top=$topDebug',
    );

    return selected.uci;
  }

  @override
  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) {
    return getBestMoveFromGame(
      startFen: 'startpos',
      moves: const <String>[],
      fen: 'startpos',
      elo: uciElo,
    );
  }

  @override
  Future<String> getBestMoveFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) {
    return getBestMoveFromGame(
      startFen: fen,
      moves: const <String>[],
      fen: fen,
      elo: uciElo,
    );
  }

  Future<List<double>> _runPolicyInference({
    required List<double> tokens,
    required int elo,
  }) async {
    if (!_isStarted) {
      throw StateError('Maia3 Windows ONNX ist nicht gestartet.');
    }

    if (tokens.length != 64 * 97) {
      throw ArgumentError.value(
        tokens.length,
        'tokens.length',
        'Maia3 erwartet genau ${64 * 97} Werte.',
      );
    }

    final rawLogits = await _channel.invokeListMethod<Object?>(
      'runInference',
      <String, Object>{
        'tokens': tokens,
        'elo': elo,
      },
    );

    if (rawLogits == null) {
      throw StateError('Maia3 Windows hat keine logits_move-Ausgabe geliefert.');
    }

    final logits = rawLogits
        .map((value) => (value as num).toDouble())
        .toList(growable: false);

    if (logits.length != 4352) {
      throw StateError(
        'Maia3 logits_move hat Länge ${logits.length}, erwartet 4352.',
      );
    }

    return logits;
  }

  List<_MaiaPolicyCandidate> _buildLegalCandidates({
    required List<double> logits,
    required List<int> legalMoveIndices,
    required List<String> legalMoveUcis,
  }) {
    if (legalMoveIndices.length != legalMoveUcis.length) {
      throw StateError(
        'Maia-Zugindizes und UCI-Züge haben unterschiedliche Längen.',
      );
    }

    final candidates = <_MaiaPolicyCandidate>[];

    for (var index = 0; index < legalMoveIndices.length; index++) {
      final maiaIndex = legalMoveIndices[index];

      if (maiaIndex < 0 || maiaIndex >= logits.length) {
        continue;
      }

      final logit = logits[maiaIndex];
      if (!logit.isFinite) {
        continue;
      }

      candidates.add(
        _MaiaPolicyCandidate(
          uci: legalMoveUcis[index],
          index: maiaIndex,
          logit: logit,
        ),
      );
    }

    if (candidates.isEmpty) {
      throw StateError('Maia3 hat keine legalen Kandidaten geliefert.');
    }

    return candidates;
  }

  _MaiaPolicyCandidate _selectMove({
    required List<_MaiaPolicyCandidate> candidates,
    required double temperature,
    required double topP,
  }) {
    if (temperature <= 0.0001 || candidates.length == 1) {
      return candidates.reduce(
        (best, candidate) => candidate.logit > best.logit ? candidate : best,
      );
    }

    final safeTemperature = temperature.clamp(0.05, 5.0).toDouble();
    final maxScaled = candidates
        .map((candidate) => candidate.logit / safeTemperature)
        .reduce(max);

    final scored = candidates
        .map(
          (candidate) => _WeightedMaiaCandidate(
            candidate: candidate,
            weight: exp(candidate.logit / safeTemperature - maxScaled),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.weight.compareTo(a.weight));

    final totalWeight = scored.fold<double>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
    final safeTopP = topP.clamp(0.01, 1.0).toDouble();
    final filtered = <_WeightedMaiaCandidate>[];
    var cumulative = 0.0;

    for (final candidate in scored) {
      filtered.add(candidate);
      cumulative += candidate.weight;

      if (cumulative / totalWeight >= safeTopP) {
        break;
      }
    }

    final filteredTotal = filtered.fold<double>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
    var roll = _random.nextDouble() * filteredTotal;

    for (final candidate in filtered) {
      roll -= candidate.weight;
      if (roll <= 0) {
        return candidate.candidate;
      }
    }

    return filtered.last.candidate;
  }

  Future<T> _runSerial<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _inferenceTail = _inferenceTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<void> _ensureStarted() async {
    if (_isStarted) {
      return;
    }

    await start();
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

    throw UnsupportedError(
      'Maia3-Windows-Kandidatenzüge sind für Botprofile nicht erforderlich.',
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

    throw UnsupportedError(
      'Maia3-Windows-Analyse ist nicht als Stockfish-Analyse gedacht.',
    );
  }

  @override
  Future<void> cancelSearch() async {
    _searchGeneration++;
    _addOutput('Maia3 Windows: laufendes Ergebnis wird verworfen.');
  }

  @override
  Future<void> stop() async {
    _searchGeneration++;

    if (!_isStarted) {
      return;
    }

    await _channel.invokeMethod<void>('dispose');
    _isStarted = false;
    _addOutput('Maia3 Windows ONNX gestoppt.');
  }

  Future<void> dispose() async {
    await stop();

    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }

  void _addOutput(String line) {
    if (!_outputController.isClosed) {
      _outputController.add(line);
    }
  }
}

class _MaiaPolicyCandidate {
  const _MaiaPolicyCandidate({
    required this.uci,
    required this.index,
    required this.logit,
  });

  final String uci;
  final int index;
  final double logit;
}

class _WeightedMaiaCandidate {
  const _WeightedMaiaCandidate({
    required this.candidate,
    required this.weight,
  });

  final _MaiaPolicyCandidate candidate;
  final double weight;
}
