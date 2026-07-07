import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bot_opening_move.dart';
import '../../models/bot_personality.dart';
import '../../models/engine_strength_mode.dart';
import '../../models/player_side.dart';

class ChessBoardControls extends StatelessWidget {
  const ChessBoardControls({
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.personaCandidateCount,
    required this.isBotThinking,
    required this.isAnalysisMode,
    required this.canNavigateAnalysisBack,
    required this.canNavigateAnalysisForward,
    required this.onNewGame,
    required this.onRestart,
    required this.onToggleAnalysisMode,
    required this.onAnalysisBack,
    required this.onAnalysisForward,
    required this.onSkillLevelChanged,
    required this.onUciEloChanged,
    required this.onCpLossEloChanged,
    required this.onCpLossUciSwitchFullMoveNumberChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    required this.onBotPersonalityChanged,
    required this.onPersonaCandidateCountChanged,
    super.key,
  });

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final int cpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final int personaCandidateCount;
  final bool isBotThinking;
  final bool isAnalysisMode;
  final bool canNavigateAnalysisBack;
  final bool canNavigateAnalysisForward;

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;
  final VoidCallback onToggleAnalysisMode;
  final Future<void> Function() onAnalysisBack;
  final Future<void> Function() onAnalysisForward;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<int> onCpLossEloChanged;
  final ValueChanged<int> onCpLossUciSwitchFullMoveNumberChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;
  final ValueChanged<BotPersonality> onBotPersonalityChanged;
  final ValueChanged<int> onPersonaCandidateCountChanged;

  String get _strengthButtonText {
    switch (strengthMode) {
      case EngineStrengthMode.level:
        return 'Level $skillLevel';
      case EngineStrengthMode.uciElo:
        return 'UCI_ELO $uciElo';
      case EngineStrengthMode.cpLossElo:
        return 'CP_Loss_ELO $cpLossElo';
    }
  }

  String get _uciSwitchButtonText {
    return 'UCI ab Zug $cpLossUciSwitchFullMoveNumber';
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

  String get _analysisButtonText {
    return isAnalysisMode ? 'Analyse ✓' : 'Analyse';
  }

  List<int> get _eloValues => [
    1320,
    ...List.generate(18, (i) => 1400 + i * 100),
    3190,
  ];

  List<int> get _cpLossEloValues {
    return List.generate(41, (index) => index * 100);
  }

  List<int> get _cpLossUciSwitchMoveValues {
    return const [6, 11, 16, 21, 26];
  }

  List<List<int>> get _cpLossEloColumns {
    const entriesPerColumn = 10;
    final values = _cpLossEloValues;
    final columns = <List<int>>[];

    for (var i = 0; i < values.length; i += entriesPerColumn) {
      final end = (i + entriesPerColumn).clamp(0, values.length).toInt();
      columns.add(values.sublist(i, end));
    }

    return columns;
  }

  List<int> get _candidateValues {
    return List.generate(32, (index) => 4 + index * 4);
  }

  List<List<int>> get _candidateColumns {
    const entriesPerColumn = 10;
    final values = _candidateValues;
    final columns = <List<int>>[];

    for (var i = 0; i < values.length; i += entriesPerColumn) {
      final end = (i + entriesPerColumn).clamp(0, values.length).toInt();
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
            _clickableDialogOption(
              child: const Text('Level'),
              onPressed: () {
                Navigator.pop(context);
                onStrengthModeChanged(EngineStrengthMode.level);
                _showLevelDialog(context);
              },
            ),
            _clickableDialogOption(
              child: const Text('UCI_ELO'),
              onPressed: () {
                Navigator.pop(context);
                onStrengthModeChanged(EngineStrengthMode.uciElo);
                _showEloDialog(context);
              },
            ),
            _clickableDialogOption(
              child: const Text('CP_Loss_ELO'),
              onPressed: () {
                Navigator.pop(context);
                onStrengthModeChanged(EngineStrengthMode.cpLossElo);
                _showCpLossEloDialog(context);
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
                (level) => _clickableDialogOption(
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
                (elo) => _clickableDialogOption(
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

  Future<void> _showCpLossEloDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('CP_Loss_ELO auswählen'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _cpLossEloColumns.map((columnValues) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columnValues.map((elo) {
                        final isSelected = elo == cpLossElo;

                        return TextButton(
                          onPressed: () {
                            onCpLossEloChanged(elo);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          child: Text(isSelected ? '✓ $elo' : '$elo'),
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

  Future<void> _showCpLossUciSwitchMoveDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('UCI_ELO ab Zug'),
          children: _cpLossUciSwitchMoveValues
              .map(
                (moveNumber) => _clickableDialogOption(
                  onPressed: () {
                    onCpLossUciSwitchFullMoveNumberChanged(moveNumber);
                    Navigator.pop(context);
                  },
                  child: Text(
                    moveNumber == cpLossUciSwitchFullMoveNumber
                        ? '✓ Zug $moveNumber'
                        : 'Zug $moveNumber',
                  ),
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
                (move) => _clickableDialogOption(
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
                (personality) => _clickableDialogOption(
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

  Widget _clickableDialogOption({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SimpleDialogOption(
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalityEnabled = botPersonality != BotPersonality.none;
    final cpLossEloEnabled = strengthMode == EngineStrengthMode.cpLossElo;
    final candidatesEnabled = personalityEnabled || cpLossEloEnabled;
    final normalControlsEnabled = !isBotThinking && !isAnalysisMode;

    final personalityButtonColor = effectiveBotPersonality.isAbstract
        ? Colors.orange
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: isAnalysisMode ? null : () => onNewGame(PlayerSide.white),
              child: const Text('Ich spiele Weiß'),
            ),
            ElevatedButton(
              onPressed: isAnalysisMode ? null : () => onNewGame(PlayerSide.black),
              child: const Text('Ich spiele Schwarz'),
            ),
            ElevatedButton(
              onPressed: isAnalysisMode ? null : onRestart,
              child: const Text('Restart'),
            ),
            ElevatedButton(
              onPressed: onToggleAnalysisMode,
              child: Text(_analysisButtonText),
            ),
            OutlinedButton.icon(
              onPressed: isAnalysisMode && canNavigateAnalysisBack
                  ? () => onAnalysisBack()
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Zurück'),
            ),
            OutlinedButton.icon(
              onPressed: isAnalysisMode && canNavigateAnalysisForward
                  ? () => onAnalysisForward()
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Vor'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: normalControlsEnabled
                  ? () => _showStrengthDialog(context)
                  : null,
              child: Text(_strengthButtonText),
            ),
            ElevatedButton(
              onPressed: normalControlsEnabled && cpLossEloEnabled
                  ? () => _showCpLossUciSwitchMoveDialog(context)
                  : null,
              child: Text(_uciSwitchButtonText),
            ),
            ElevatedButton(
              onPressed: normalControlsEnabled
                  ? () => _showOpeningDialog(context)
                  : null,
              child: Text(botOpeningMove.label),
            ),
            ElevatedButton(
              onPressed: normalControlsEnabled
                  ? () => _showPersonalityDialog(context)
                  : null,
              child: Text(
                _personalityButtonText,
                style: TextStyle(color: personalityButtonColor),
              ),
            ),
            ElevatedButton(
              onPressed: normalControlsEnabled && candidatesEnabled
                  ? () => _showCandidateDialog(context)
                  : null,
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
    final isAbstract = personality.isAbstract;
    final style = isAbstract ? const TextStyle(color: Colors.orange) : null;

    if (personality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      final effectiveText = effectiveBotPersonality.isAbstract
          ? '${personality.label} (${effectiveBotPersonality.label})'
          : '${personality.label} (${effectiveBotPersonality.label})';

      return Text(
        effectiveText,
        style: effectiveBotPersonality.isAbstract
            ? const TextStyle(color: Colors.orange)
            : null,
      );
    }

    return Text(personality.label, style: style);
  }
}
