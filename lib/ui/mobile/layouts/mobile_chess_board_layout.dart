import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/player_side.dart';
import '../widgets/chess_board/mobile_chess_board_view.dart';
import '../widgets/mobile_chess_bottom_view.dart';
import '../widgets/mobile_chess_copy_pgn_button.dart';
import '../widgets/mobile_chess_top_controls.dart';

class MobileChessBoardLayout extends StatelessWidget {
  const MobileChessBoardLayout({
    super.key,
    required this.statusText,
    required this.playerSideText,
    required this.pgnText,
    required this.playerIsWhite,
    required this.pieceAt,
    required this.onSquareTap,
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.personaCandidateCount,
    required this.onNewGame,
    required this.onRestart,
    required this.onSkillLevelChanged,
    required this.onUciEloChanged,
    required this.onCpLossEloChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    required this.onBotPersonalityChanged,
    required this.onPersonaCandidateCountChanged,
    this.controlsEnabled = true,
  });

  final String statusText;
  final String playerSideText;
  final String pgnText;

  final bool playerIsWhite;
  final chess.Piece? Function(String square) pieceAt;
  final Future<void> Function(String square) onSquareTap;

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final int personaCandidateCount;

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<int> onCpLossEloChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;
  final ValueChanged<BotPersonality> onBotPersonalityChanged;
  final ValueChanged<int> onPersonaCandidateCountChanged;

  final bool controlsEnabled;

  static const double _screenPadding = 16;

  static const double _topControlsHeight = 104;

  static const double _bottomViewHeight = 96;
  static const double _copyPgnButtonHeight = 44;
  static const double _bottomGap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (_screenPadding * 2);
        final availableHeight = constraints.maxHeight - (_screenPadding * 2);
        final boardSize = math.min(availableWidth, availableHeight);

        final verticalFreeSpace = constraints.maxHeight - boardSize;
        final spaceAboveBoard = math.max(0.0, (verticalFreeSpace / 2) - 8);
        final spaceBelowBoard = math.max(0.0, (verticalFreeSpace / 2) - 8);

        final canShowTopControls = spaceAboveBoard >= _topControlsHeight;
        final canShowBottomView =
            spaceBelowBoard >=
            (_bottomViewHeight + _bottomGap + _copyPgnButtonHeight);

        final canShowCopyPgnOnly =
            !canShowBottomView && spaceBelowBoard >= _copyPgnButtonHeight;

        return Stack(
          children: [
            Center(
              child: SizedBox.square(
                dimension: boardSize,
                child: MobileChessBoardView(
                  playerIsWhite: playerIsWhite,
                  pieceAt: pieceAt,
                  onSquareTap: onSquareTap,
                ),
              ),
            ),
            if (canShowTopControls)
              Positioned(
                left: _screenPadding,
                right: _screenPadding,
                top: 0,
                height: _topControlsHeight,
                child: MobileChessTopControls(
                  skillLevel: skillLevel,
                  uciElo: uciElo,
                  cpLossElo: cpLossElo,
                  strengthMode: strengthMode,
                  botOpeningMove: botOpeningMove,
                  botPersonality: botPersonality,
                  effectiveBotPersonality: effectiveBotPersonality,
                  personaCandidateCount: personaCandidateCount,
                  onNewGame: onNewGame,
                  onRestart: onRestart,
                  onSkillLevelChanged: onSkillLevelChanged,
                  onUciEloChanged: onUciEloChanged,
                  onCpLossEloChanged: onCpLossEloChanged,
                  onStrengthModeChanged: onStrengthModeChanged,
                  onBotOpeningMoveChanged: onBotOpeningMoveChanged,
                  onBotPersonalityChanged: onBotPersonalityChanged,
                  onPersonaCandidateCountChanged:
                      onPersonaCandidateCountChanged,
                  isEnabled: controlsEnabled,
                ),
              ),
            if (canShowBottomView)
              Positioned(
                left: _screenPadding,
                right: _screenPadding,
                bottom: 0,
                height: _bottomViewHeight + _bottomGap + _copyPgnButtonHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MobileChessBottomView(
                      statusText: statusText,
                      playerSideText: playerSideText,
                      pgnText: pgnText,
                    ),
                    const SizedBox(height: _bottomGap),
                    MobileChessCopyPgnButton(pgnText: pgnText),
                  ],
                ),
              )
            else if (canShowCopyPgnOnly)
              Positioned(
                left: _screenPadding,
                right: _screenPadding,
                bottom: 0,
                height: _copyPgnButtonHeight,
                child: MobileChessCopyPgnButton(pgnText: pgnText),
              ),
          ],
        );
      },
    );
  }
}
