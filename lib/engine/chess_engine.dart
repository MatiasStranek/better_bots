abstract class ChessEngine {
  Stream<String> get output;

  bool get isRunning;

  Future<void> start();

  Future<void> stop();

  Future<void> setSkillLevel(int level);

  Future<String> getBestMoveFromStartPosition({
    required int skillLevel,
    int moveTimeMs = 800,
  });

  Future<String> getBestMoveFromFen({
    required String fen,
    required int skillLevel,
    int moveTimeMs = 800,
  });
}
