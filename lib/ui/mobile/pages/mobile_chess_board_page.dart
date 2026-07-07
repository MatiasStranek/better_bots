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
      onPromotionChoiceRequested: _showPromotionChoiceDialog,
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

  Future<String?> _showPromotionChoiceDialog({
    required String from,
    required String to,
    required PlayerSide playerSide,
  }) async {
    if (!mounted) {
      return null;
    }

    final sideName = playerSide == PlayerSide.white ? 'Weiß' : 'Schwarz';

    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(170),
      builder: (context) {
        return _MobilePromotionChoiceSheet(
          title: 'Bauernumwandlung',
          subtitle: '$sideName wandelt den Bauern von $from nach $to um.',
        );
      },
    );
  }

  void _handleToggleAnalysisMode() {
    _controller.toggleAnalysisMode();
  }

  Future<void> _handleAnalysisBack() async {
    await _controller.stepAnalysisBack();
  }

  Future<void> _handleAnalysisForward() async {
    await _controller.stepAnalysisForward();
  }

  void _handleSystemBackWhileInAnalysisMode() {
    if (!_controller.isAnalysisMode) {
      return;
    }

    _controller.toggleAnalysisMode();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return PopScope(
          canPop: !_controller.isAnalysisMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }

            _handleSystemBackWhileInAnalysisMode();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: SafeArea(
              child: MobileChessBoardLayout(
                statusText: _controller.statusText,
                playerSideText: _playerSideText,
                pgnText: _controller.pgn,
                fenText: _controller.fen,

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
                cpLossUciSwitchFullMoveNumber:
                    _controller.cpLossUciSwitchFullMoveNumber,
                strengthMode: _controller.strengthMode,
                botOpeningMove: _controller.botOpeningMove,
                botPersonality: _controller.botPersonality,
                effectiveBotPersonality: _controller.effectiveBotPersonality,
                personaCandidateCount: _controller.personaCandidateCount,
                controlsEnabled: !_controller.isBotThinking,

                isAnalysisMode: _controller.isAnalysisMode,
                analysisLines: _controller.analysisLines,
                canToggleAnalysisMode: _controller.canToggleAnalysisMode,
                canNavigateAnalysisBack: _controller.canNavigateAnalysisBack,
                canNavigateAnalysisForward: _controller.canNavigateAnalysisForward,
                onToggleAnalysisMode: _handleToggleAnalysisMode,
                onAnalysisBack: _handleAnalysisBack,
                onAnalysisForward: _handleAnalysisForward,

                onNewGame: _controller.newGame,
                onRestart: _controller.restartGame,

                onSkillLevelChanged: _controller.setSkillLevel,
                onUciEloChanged: _controller.setUciElo,
                onCpLossEloChanged: _controller.setCpLossElo,
                onCpLossUciSwitchFullMoveNumberChanged:
                    _controller.setCpLossUciSwitchFullMoveNumber,
                onStrengthModeChanged: _controller.setStrengthMode,
                onBotOpeningMoveChanged: _controller.setBotOpeningMove,
                onBotPersonalityChanged: _controller.setBotPersonality,
                onPersonaCandidateCountChanged:
                    _controller.setPersonaCandidateCount,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobilePromotionChoiceSheet extends StatelessWidget {
  const _MobilePromotionChoiceSheet({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _PromotionChoiceButton(
            icon: Icons.star,
            label: 'Dame',
            notation: 'q',
            onTap: () => Navigator.of(context).pop('q'),
          ),
          _PromotionChoiceButton(
            icon: Icons.castle,
            label: 'Turm',
            notation: 'r',
            onTap: () => Navigator.of(context).pop('r'),
          ),
          _PromotionChoiceButton(
            icon: Icons.change_history,
            label: 'Läufer',
            notation: 'b',
            onTap: () => Navigator.of(context).pop('b'),
          ),
          _PromotionChoiceButton(
            icon: Icons.pets,
            label: 'Springer',
            notation: 'n',
            onTap: () => Navigator.of(context).pop('n'),
          ),
        ],
      ),
    );
  }
}

class _PromotionChoiceButton extends StatelessWidget {
  const _PromotionChoiceButton({
    required this.icon,
    required this.label,
    required this.notation,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String notation;
  final VoidCallback onTap;

  static const Color _accentColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 30, color: _accentColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  notation.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
