import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/player_side.dart';

class MobileChessSideMenu extends StatelessWidget {
  const MobileChessSideMenu({
    super.key,
    required this.width,
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.effectiveBotOpeningMove,
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
    required this.onClose,
    this.isEnabled = true,
  });

  final double width;

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final int cpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotOpeningMove effectiveBotOpeningMove;
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

  final VoidCallback onClose;
  final bool isEnabled;

  static const Color _accentColor = Color(0xFF5C9DFF);

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

  String get _openingButtonText {
    if (botOpeningMove == BotOpeningMove.random) {
      return 'Zufällig: ${effectiveBotOpeningMove.label}';
    }

    return botOpeningMove.label;
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

  void _startNewGame(PlayerSide side) {
    if (!isEnabled) {
      return;
    }

    onClose();
    onNewGame(side);
  }

  void _restartGame() {
    if (!isEnabled) {
      return;
    }

    onClose();
    onRestart();
  }

  @override
  Widget build(BuildContext context) {
    final personalityEnabled = botPersonality != BotPersonality.none;
    final cpLossEloEnabled = strengthMode == EngineStrengthMode.cpLossElo;
    final candidatesEnabled = personalityEnabled || cpLossEloEnabled;

    return SizedBox(
      width: width,
      height: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF171717),
          image: DecorationImage(
            image: AssetImage('assets/background/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withAlpha(80),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                const Center(child: FlutterLogo(size: 72)),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Better Bots',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _SideMenuButton(
                  icon: Icons.speed,
                  label: 'Spielstärke',
                  value: _strengthButtonText,
                  onTap: () => _showStrengthDialog(context),
                  isEnabled: isEnabled,
                  isHighlighted: true,
                ),
                _SideMenuButton(
                  icon: Icons.call_split,
                  label: 'Eröffnung',
                  value: _openingButtonText,
                  onTap: () => _showOpeningDialog(context),
                  isEnabled: isEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.psychology,
                  label: 'Persönlichkeit',
                  value: _personalityButtonText,
                  onTap: () => _showPersonalityDialog(context),
                  isEnabled: isEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.list,
                  label: 'Kandidaten',
                  value: _candidateButtonText,
                  onTap: () => _showCandidateDialog(context),
                  isEnabled: isEnabled && candidatesEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.swap_horiz,
                  label: 'UCI_ELO Switch',
                  value: _uciSwitchButtonText,
                  onTap: () => _showCpLossUciSwitchMoveDialog(context),
                  isEnabled: isEnabled && cpLossEloEnabled,
                ),
                const SizedBox(height: 18),
                Divider(color: Colors.white.withAlpha(55), height: 24),
                const SizedBox(height: 6),
                _SideMenuButton(
                  icon: Icons.circle_outlined,
                  label: 'Neue Partie Weiß',
                  value: 'Du spielst Weiß',
                  onTap: () => _startNewGame(PlayerSide.white),
                  isEnabled: isEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.circle,
                  label: 'Neue Partie Schwarz',
                  value: 'Du spielst Schwarz',
                  onTap: () => _startNewGame(PlayerSide.black),
                  isEnabled: isEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.refresh,
                  label: 'Restart',
                  value: 'Aktuelle Seite neu starten',
                  onTap: _restartGame,
                  isEnabled: isEnabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideMenuButton extends StatelessWidget {
  const _SideMenuButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEnabled,
    this.isHighlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEnabled;
  final bool isHighlighted;
  final VoidCallback? onTap;

  static const Color _accentColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? isHighlighted
              ? _accentColor
              : Colors.white
        : Colors.white.withAlpha(76);

    final valueColor = isEnabled
        ? Colors.white.withAlpha(170)
        : Colors.white.withAlpha(76);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
