import 'package:flutter/material.dart';

import '../../models/player_side.dart';

class ChessBoardControls extends StatelessWidget {
  const ChessBoardControls({
    required this.skillLevel,
    required this.isBotThinking,
    required this.onNewGame,
    required this.onRestart,
    required this.onSkillLevelChanged,
    super.key,
  });

  final int skillLevel;
  final bool isBotThinking;
  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;
  final ValueChanged<int> onSkillLevelChanged;

  @override
  Widget build(BuildContext context) {
    final levels = List.generate(21, (index) => index);

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
        Row(
          children: [
            const Text('Spielstärke:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: skillLevel,
              items: levels.map((level) {
                return DropdownMenuItem<int>(
                  value: level,
                  child: Text('Level $level'),
                );
              }).toList(),
              onChanged: isBotThinking
                  ? null
                  : (value) {
                      if (value == null) return;
                      onSkillLevelChanged(value);
                    },
            ),
          ],
        ),
      ],
    );
  }
}
