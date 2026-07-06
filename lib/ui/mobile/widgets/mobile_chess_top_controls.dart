import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/player_side.dart';

class MobileChessTopControls extends StatelessWidget {
  const MobileChessTopControls({
    super.key,
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
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
    required this.onCpLossUciSwitchFullMoveNumberChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    required this.onBotPersonalityChanged,
    required this.onPersonaCandidateCountChanged,
    this.isEnabled = true,
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

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<int> onCpLossEloChanged;
  final ValueChanged<int> onCpLossUciSwitchFullMoveNumberChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;
  final ValueChanged<BotPersonality> onBotPersonalityChanged;
  final ValueChanged<int> onPersonaCandidateCountChanged;

  final bool isEnabled;

  String get _strengthButtonText {
    switch (strengthMode) {
      case EngineStrengthMode.level:
        return 'Level $skillLevel';
      case EngineStrengthMode.uciElo:
        return 'UCI $uciElo';
      case EngineStrengthMode.cpLossElo:
        return 'CP $cpLossElo';
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

  List<int> get _eloValues {
    return [1320, ...List.generate(18, (index) => 1400 + index * 100), 3190];
  }

  List<int> get _cpLossEloValues {
    return List.generate(41, (index) => index * 100);
  }

  List<int> get _cpLossUciSwitchMoveValues {
    return const [6, 11, 16, 21, 26];
  }

  List<int> get _candidateValues {
    return List.generate(32, (index) => 4 + index * 4);
  }

  Future<void> _showStrengthDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Spielstärke'),
          children: [
            SimpleDialogOption(
              child: const Text('Level'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onStrengthModeChanged(EngineStrengthMode.level);
                _showLevelDialog(context);
              },
            ),
            SimpleDialogOption(
              child: const Text('UCI_ELO'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onStrengthModeChanged(EngineStrengthMode.uciElo);
                _showUciEloDialog(context);
              },
            ),
            SimpleDialogOption(
              child: const Text('CP_Loss_ELO'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
    final levels = List.generate(21, (index) => index);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Level auswählen'),
          children: levels.map((level) {
            return SimpleDialogOption(
              onPressed: () {
                onSkillLevelChanged(level);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                level == skillLevel ? '✓ Level $level' : 'Level $level',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showUciEloDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('UCI_ELO auswählen'),
          children: _eloValues.map((elo) {
            return SimpleDialogOption(
              onPressed: () {
                onUciEloChanged(elo);
                Navigator.of(dialogContext).pop();
              },
              child: Text(elo == uciElo ? '✓ $elo' : '$elo'),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showCpLossEloDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('CP_Loss_ELO auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cpLossEloValues.map((elo) {
                  final isSelected = elo == cpLossElo;

                  return ChoiceChip(
                    label: Text('$elo'),
                    selected: isSelected,
                    onSelected: (_) {
                      onCpLossEloChanged(elo);
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCpLossUciSwitchMoveDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('UCI_ELO ab Zug'),
          children: _cpLossUciSwitchMoveValues.map((moveNumber) {
            return SimpleDialogOption(
              onPressed: () {
                onCpLossUciSwitchFullMoveNumberChanged(moveNumber);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                moveNumber == cpLossUciSwitchFullMoveNumber
                    ? '✓ Zug $moveNumber'
                    : 'Zug $moveNumber',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showOpeningDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Eröffnung auswählen'),
          children: BotOpeningMove.values.map((move) {
            return SimpleDialogOption(
              onPressed: () {
                onBotOpeningMoveChanged(move);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                move == botOpeningMove ? '✓ ${move.label}' : move.label,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showPersonalityDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Persönlichkeit auswählen'),
          children: BotPersonality.values.map((personality) {
            return SimpleDialogOption(
              onPressed: () {
                onBotPersonalityChanged(personality);
                Navigator.of(dialogContext).pop();
              },
              child: _PersonalityDialogLabel(
                personality: personality,
                selectedPersonality: botPersonality,
                effectiveBotPersonality: effectiveBotPersonality,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showCandidateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kandidatenzüge auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _candidateValues.map((candidateCount) {
                  final isSelected = candidateCount == personaCandidateCount;

                  return ChoiceChip(
                    label: Text('$candidateCount'),
                    selected: isSelected,
                    onSelected: (_) {
                      onPersonaCandidateCountChanged(candidateCount);
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalityEnabled = botPersonality != BotPersonality.none;
    final cpLossEloEnabled = strengthMode == EngineStrengthMode.cpLossElo;
    final candidatesEnabled = personalityEnabled || cpLossEloEnabled;

    return SizedBox(
      height: 160,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MobileTopControlButton(
                  label: 'Weiß',
                  icon: Icons.circle_outlined,
                  onPressed: isEnabled
                      ? () => onNewGame(PlayerSide.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTopControlButton(
                  label: 'Schwarz',
                  icon: Icons.circle,
                  onPressed: isEnabled
                      ? () => onNewGame(PlayerSide.black)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTopControlButton(
                  label: 'Restart',
                  icon: Icons.refresh,
                  onPressed: isEnabled ? onRestart : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MobileTopControlButton(
                  label: _strengthButtonText,
                  icon: Icons.speed,
                  onPressed: isEnabled
                      ? () => _showStrengthDialog(context)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTopControlButton(
                  label: botOpeningMove.label,
                  icon: Icons.call_split,
                  onPressed: isEnabled
                      ? () => _showOpeningDialog(context)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTopControlButton(
                  label: _personalityButtonText,
                  icon: Icons.psychology,
                  onPressed: isEnabled
                      ? () => _showPersonalityDialog(context)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTopControlButton(
                  label: _candidateButtonText,
                  icon: Icons.list,
                  onPressed: isEnabled && candidatesEnabled
                      ? () => _showCandidateDialog(context)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MobileTopControlButton(
                  label: _uciSwitchButtonText,
                  icon: Icons.swap_horiz,
                  onPressed: isEnabled && cpLossEloEnabled
                      ? () => _showCpLossUciSwitchMoveDialog(context)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileTopControlButton extends StatelessWidget {
  const _MobileTopControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }
}

class _PersonalityDialogLabel extends StatelessWidget {
  const _PersonalityDialogLabel({
    required this.personality,
    required this.selectedPersonality,
    required this.effectiveBotPersonality,
  });

  final BotPersonality personality;
  final BotPersonality selectedPersonality;
  final BotPersonality effectiveBotPersonality;

  @override
  Widget build(BuildContext context) {
    final isSelected = personality == selectedPersonality;

    if (personality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      final text = '${personality.label} (${effectiveBotPersonality.label})';

      return Text(isSelected ? '✓ $text' : text);
    }

    return Text(isSelected ? '✓ ${personality.label}' : personality.label);
  }
}
