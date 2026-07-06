import 'package:flutter/material.dart';

import '../../../controllers/chess_board_controller.dart';
import '../../../engine/chess_engine_factory.dart';
import '../../../models/player_side.dart';
import '../layouts/mobile_chess_board_layout.dart';

class MobileChessBoardPage extends StatefulWidget {
  const MobileChessBoardPage({super.key});

  @override
  State<MobileChessBoardPage> createState() => _MobileChessBoardPageState();
}

class _MobileChessBoardPageState extends State<MobileChessBoardPage> {
  late final ChessBoardController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ChessBoardController(
      engine: ChessEngineFactory.createMobileEngine(),
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _playerSideText {
    return _controller.playerSide == PlayerSide.white ? 'Weiß' : 'Schwarz';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return MobileChessBoardLayout(
              statusText: _controller.statusText,
              playerSideText: _playerSideText,
              pgnText: _controller.pgn,

              playerIsWhite: _controller.playerIsWhite,
              pieceAt: _controller.pieceAt,
              highlights: _controller.highlights,

              canHumanMovePiece: _controller.canHumanMovePiece,
              canMoveTo: _controller.canMoveTo,

              onSquareTap: _controller.onSquareTap,
              onMove: _controller.tryHumanMove,

              onPieceDragStarted: _controller.selectSquare,
              onPieceDragEnded: _controller.clearSelectedSquare,

              skillLevel: _controller.skillLevel,
              uciElo: _controller.uciElo,
              cpLossElo: _controller.cpLossElo,
              strengthMode: _controller.strengthMode,
              botOpeningMove: _controller.botOpeningMove,
              botPersonality: _controller.botPersonality,
              effectiveBotPersonality: _controller.effectiveBotPersonality,
              personaCandidateCount: _controller.personaCandidateCount,
              controlsEnabled: !_controller.isBotThinking,

              onNewGame: _controller.newGame,
              onRestart: _controller.restartGame,

              onSkillLevelChanged: _controller.setSkillLevel,
              onUciEloChanged: _controller.setUciElo,
              onCpLossEloChanged: _controller.setCpLossElo,
              onStrengthModeChanged: _controller.setStrengthMode,
              onBotOpeningMoveChanged: _controller.setBotOpeningMove,
              onBotPersonalityChanged: _controller.setBotPersonality,
              onPersonaCandidateCountChanged:
                  _controller.setPersonaCandidateCount,
            );
          },
        ),
      ),
    );
  }
}
