import 'package:flutter/material.dart';

import '../../models/bot_opening_move.dart';
import '../../models/bot_personality.dart';
import '../../models/engine_strength_mode.dart';
import '../../models/player_side.dart';

class ChessBoardControls extends StatelessWidget {
  const ChessBoardControls({
    required this.skillLevel,
    required this.uciElo,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.personaCandidateCount,
    required this.isBotThinking,
    required this.onNewGame,
    required this.onRestart,
    required this.onSkillLevelChanged,
    required this.onUciEloChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    required this.onBotPersonalityChanged,
    required this.onPersonaCandidateCountChanged,
    super.key,
  });

  final int skillLevel;
  final int uciElo;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final int personaCandidateCount;
  final bool isBotThinking;

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;
  final ValueChanged<BotPersonality> onBotPersonalityChanged;
  final ValueChanged<int> onPersonaCandidateCountChanged;

  String get _strengthButtonText {
    if (strengthMode == EngineStrengthMode.level) {
      return 'Level $skillLevel';
    }

    return 'UCI_ELO $uciElo';
  }

  String get _personalityButtonText {
    if (botPersonality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      return 'Zufällig: ${effectiveBotPersonality.label}';
    }

    return botPersonality.label;
  }

  String get _candidateButtonText {
    return 'Kandidaten: $personaCandidateCount';
  }

  List<int> get _eloValues => [
    1320,
    ...List.generate(18, (i) => 1400 + i * 100),
    3190,
  ];

  List<int> get _candidateValues {
    return List.generate(32, (index) => 4 + index * 4);
  }

  List<List<int>> get _candidateColumns {
    const entriesPerColumn = 10;
    final values = _candidateValues;
    final columns = <List<int>>[];

    for (var i = 0; i < values.length; i += entriesPerColumn) {
      final end = (i + entriesPerColumn).clamp(0, values.length);
      columns.add(values.sublist(i, end));
    }

    return columns;
  }

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

  Future<void> _showPersonalityDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Persönlichkeit auswählen'),
          children: BotPersonality.values
              .map(
                (personality) => SimpleDialogOption(
                  onPressed: () {
                    onBotPersonalityChanged(personality);
                    Navigator.pop(context);
                  },
                  child: _PersonalityDialogLabel(
                    personality: personality,
                    effectiveBotPersonality: effectiveBotPersonality,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _showCandidateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Kandidatenzüge auswählen'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _candidateColumns.map((columnValues) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 130,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columnValues.map((candidateCount) {
                        final isSelected =
                            candidateCount == personaCandidateCount;

                        return TextButton(
                          onPressed: () {
                            onPersonaCandidateCountChanged(candidateCount);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            isSelected
                                ? '✓ $candidateCount Kandidaten'
                                : '$candidateCount Kandidaten',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalityEnabled = botPersonality != BotPersonality.none;

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
              child: Text(_strengthButtonText),
            ),
            ElevatedButton(
              onPressed: isBotThinking
                  ? null
                  : () => _showOpeningDialog(context),
              child: Text(botOpeningMove.label),
            ),
            ElevatedButton(
              onPressed: isBotThinking
                  ? null
                  : () => _showPersonalityDialog(context),
              child: Text(_personalityButtonText),
            ),
            ElevatedButton(
              onPressed: isBotThinking || !personalityEnabled
                  ? null
                  : () => _showCandidateDialog(context),
              child: Text(_candidateButtonText),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonalityDialogLabel extends StatelessWidget {
  const _PersonalityDialogLabel({
    required this.personality,
    required this.effectiveBotPersonality,
  });

  final BotPersonality personality;
  final BotPersonality effectiveBotPersonality;

  @override
  Widget build(BuildContext context) {
    if (personality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      return Text('${personality.label} (${effectiveBotPersonality.label})');
    }

    return Text(personality.label);
  }
}
