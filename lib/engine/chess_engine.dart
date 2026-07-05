import 'personality/persona_move_candidate.dart';

abstract class ChessEngine {
  Stream<String> get output;

  bool get isRunning;

  Future<void> start();

  Future<void> setSkillLevel(int level);

  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  });

  Future<String> getBestMoveFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    int moveTimeMs = 800,
  });

  Future<List<PersonaMoveCandidate>> getMoveCandidatesFromFen({
    required String fen,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    required int candidateCount,
    int moveTimeMs = 800,
  });

  Future<void> stop();
}
