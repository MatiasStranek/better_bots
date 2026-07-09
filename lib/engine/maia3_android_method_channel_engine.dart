import 'dart:async';

import 'package:flutter/services.dart';

import '../models/engine_analysis_line.dart';
import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class Maia3AndroidMethodChannelEngine implements ChessEngine {
  Maia3AndroidMethodChannelEngine();

  static const MethodChannel _channel = MethodChannel('better_bots/maia3');

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  bool _isRunning = false;

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _addOutput('Maia3 Android Bridge startet.');

    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'maia3Init',
        <String, Object?>{
          'model': 'maia3-5m',
        },
      );

      final message = response?['message']?.toString();

      if (message == null || message.isEmpty) {
        _addOutput('Maia3 Android Bridge bereit.');
      } else {
        _addOutput('Maia3 Android Bridge: $message');
      }
    } on PlatformException catch (e) {
      _addOutput(_platformExceptionText(e));
    } catch (e) {
      _addOutput('Maia3 Android Bridge Fehler: $e');
    }
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

    _addOutput(
      'Maia3 Android angefragt: Elo $elo, '
      '${moves.length} Halbzüge History.',
    );

    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'maia3GetBestMove',
        <String, Object?>{
          'startFen': startFen,
          'moves': moves,
          'fen': fen,
          'elo': elo,
          'temperature': temperature,
          'topP': topP,
        },
      );

      final bestMove = response?['bestMove']?.toString().trim() ?? '';

      if (bestMove.isEmpty) {
        throw StateError('Maia3 Android hat keinen bestMove zurückgegeben.');
      }

      _addOutput('Maia3 Android bestmove $bestMove');

      return bestMove;
    } on PlatformException catch (e) {
      throw UnsupportedError(_platformExceptionText(e));
    }
  }

  @override
  Future<void> setSkillLevel(int level) async {
    // Maia3 nutzt Rating-Conditioning über Elo statt Stockfish Skill-Level.
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
      'Maia3 Android Kandidatenzüge sind noch nicht implementiert.',
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
      'Maia3 Android Analyse ist noch nicht implementiert.',
    );
  }

  @override
  Future<void> cancelSearch() async {
    _addOutput('Maia3 Android: Suche abgebrochen.');
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _addOutput('Maia3 Android Bridge gestoppt.');
  }

  Future<void> _ensureStarted() async {
    if (_isRunning) {
      return;
    }

    await start();
  }

  String _platformExceptionText(PlatformException exception) {
    final message = exception.message;

    if (message == null || message.isEmpty) {
      return 'Maia3 Android Fehler: ${exception.code}';
    }

    return 'Maia3 Android Fehler: ${exception.code} – $message';
  }

  void _addOutput(String line) {
    if (_outputController.isClosed) {
      return;
    }

    _outputController.add(line);
  }
}
