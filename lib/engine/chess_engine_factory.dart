import 'chess_engine.dart';
import 'noop_chess_engine.dart';

class ChessEngineFactory {
  const ChessEngineFactory._();

  static ChessEngine createMobileEngine() {
    return NoopChessEngine();
  }
}
