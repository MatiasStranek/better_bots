import 'dart:async';

import 'chess_engine.dart';
import 'personality/persona_move_candidate.dart';

class NoopChessEngine implements ChessEngine {
  NoopChessEngine();

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  bool _isRunning = false;

  @override
  Stream<String> get output => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() async {
    _isRunning = true;
    _outputController.add('NoopChessEngine gestartet.');
  }

  @override
  Future<void> setSkillLevel(int level) async {
    _outputController.add(
      'NoopChessEngine: Skill-Level $level wurde ignoriert.',
    );
  }

  @override
  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    _outputController.add('NoopChessEngine: Kein Bot-Zug verfügbar.');

    return '';
  }

  @override
  Future<String> getBestMoveFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  }) async {
    _outputController.add('NoopChessEngine: Kein Bot-Zug für FEN verfügbar.');

    return '';
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
    _outputController.add('NoopChessEngine: Keine Kandidatenzüge verfügbar.');

    return [];
  }

  @override
  Future<void> stop() async {
    _isRunning = false;

    if (!_outputController.isClosed) {
      _outputController.add('NoopChessEngine gestoppt.');
      await _outputController.close();
    }
  }
}
