import 'package:flutter/material.dart';

import '../../models/bot_opening_move.dart';
import '../../models/engine_strength_mode.dart';
import '../../models/player_side.dart';

class ChessBoardControls extends StatelessWidget {
  const ChessBoardControls({
    required this.skillLevel,
    required this.uciElo,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.isBotThinking,
    required this.onNewGame,
    required this.onRestart,
    required this.onSkillLevelChanged,
    required this.onUciEloChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    super.key,
  });

  final int skillLevel;
  final int uciElo;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final bool isBotThinking;

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;

  String get _buttonText {
    if (strengthMode == EngineStrengthMode.level) {
      return 'Level $skillLevel';
    }

    return 'UCI_ELO $uciElo';
  }

  List<int> get _eloValues => [
    1320,
    ...List.generate(18, (i) => 1400 + i * 100),
    3190,
  ];

  Future<void> _showStrengthDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Spielstärke'),
          children: [
            SimpleDialogOption(
              child: const Text('Level'),
              onPressed: () {
                Navigator.pop(context);
                onStrengthModeChanged(EngineStrengthMode.level);
                _showLevelDialog(context);
              },
            ),
            SimpleDialogOption(
              child: const Text('UCI_ELO'),
              onPressed: () {
                Navigator.pop(context);
                onStrengthModeChanged(EngineStrengthMode.uciElo);
                _showEloDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLevelDialog(BuildContext context) async {
    final levels = List.generate(21, (i) => i);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Level auswählen'),
          children: levels
              .map(
                (level) => SimpleDialogOption(
                  onPressed: () {
                    onSkillLevelChanged(level);
                    Navigator.pop(context);
                  },
                  child: Text('Level $level'),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _showEloDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('UCI_ELO auswählen'),
          children: _eloValues
              .map(
                (elo) => SimpleDialogOption(
                  onPressed: () {
                    onUciEloChanged(elo);
                    Navigator.pop(context);
                  },
                  child: Text('$elo'),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _showOpeningDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Eröffnung auswählen'),
          children: BotOpeningMove.values
              .map(
                (move) => SimpleDialogOption(
                  onPressed: () {
                    onBotOpeningMoveChanged(move);
                    Navigator.pop(context);
                  },
                  child: Text(move.label),
                ),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => onNewGame(PlayerSide.white),
              child: const Text('Ich spiele Weiß'),
            ),
            ElevatedButton(
              onPressed: () => onNewGame(PlayerSide.black),
              child: const Text('Ich spiele Schwarz'),
            ),
            ElevatedButton(onPressed: onRestart, child: const Text('Restart')),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: isBotThinking
                  ? null
                  : () => _showStrengthDialog(context),
              child: Text(_buttonText),
            ),
            ElevatedButton(
              onPressed: isBotThinking
                  ? null
                  : () => _showOpeningDialog(context),
              child: Text(botOpeningMove.label),
            ),
          ],
        ),
      ],
    );
  }
}
