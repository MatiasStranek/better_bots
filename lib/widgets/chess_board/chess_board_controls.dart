import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bot_opening_move.dart';
import '../../models/bot_personality.dart';
import '../../models/engine_strength_mode.dart';
import '../../models/player_side.dart';

const Color _analysisButtonForeground = Color(0xFFFF9800);
const Color _dialogAccentBlue = Color(0xFF2E5F93);
const TextStyle _dialogTitleTextStyle = TextStyle(color: Colors.black);
const TextStyle _dialogSelectableTextStyle = TextStyle(
  color: _dialogAccentBlue,
);

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
    ...List.generate(18, (index) => 1400 + index * 100),
    3190,
  ];

  List<int> get _cpLossEloValues {
    return List.generate(41, (index) => index * 100);
  }

  List<int> get _cpLossUciSwitchMoveValues {
    return const [6, 11, 16, 21, 26];
  }

  List<List<int>> get _levelColumns {
    return _columnsFromValues(List.generate(21, (index) => index), 5);
  }

  List<List<int>> get _uciEloColumns {
    return _columnsFromValues(_eloValues, 5);
  }

  List<List<int>> get _cpLossEloColumns {
    return _columnsFromValues(_cpLossEloValues, 10);
  }

  List<int> get _candidateValues {
    return List.generate(32, (index) => 4 + index * 4);
  }

  List<List<int>> get _candidateColumns {
    return _columnsFromValues(_candidateValues, 10);
  }

  List<List<int>> _columnsFromValues(List<int> values, int entriesPerColumn) {
    final columns = <List<int>>[];

    for (var i = 0; i < values.length; i += entriesPerColumn) {
      final end = (i + entriesPerColumn).clamp(0, values.length).toInt();
      columns.add(values.sublist(i, end));
    }

    return columns;
  }

  int get _strengthDialogInitialTabIndex {
    switch (strengthMode) {
      case EngineStrengthMode.level:
        return 0;
      case EngineStrengthMode.uciElo:
        return 1;
      case EngineStrengthMode.cpLossElo:
        return 2;
    }
  }

  Future<void> _showStrengthDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return DefaultTabController(
          initialIndex: _strengthDialogInitialTabIndex,
          length: 3,
          child: AlertDialog(
            title: const Text(
              'Spielstärke',
              style: _dialogTitleTextStyle,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            content: SizedBox(
              width: 920,
              height: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    labelColor: _dialogAccentBlue,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: _dialogAccentBlue,
                    tabs: [
                      Tab(text: 'Level'),
                      Tab(text: 'UCI_ELO'),
                      Tab(text: 'CP_Loss_ELO'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLevelStrengthTab(dialogContext),
                        _buildUciEloStrengthTab(dialogContext),
                        _buildCpLossEloStrengthTab(dialogContext),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelStrengthTab(BuildContext context) {
    return _strengthValueColumns(
      columns: _levelColumns,
      columnWidth: 128,
      labelBuilder: (level) => 'Level $level',
      isSelected: (level) {
        return strengthMode == EngineStrengthMode.level && level == skillLevel;
      },
      onSelected: (level) {
        onStrengthModeChanged(EngineStrengthMode.level);
        onSkillLevelChanged(level);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildUciEloStrengthTab(BuildContext context) {
    return _strengthValueColumns(
      columns: _uciEloColumns,
      columnWidth: 132,
      labelBuilder: (elo) => '$elo',
      isSelected: (elo) {
        return strengthMode == EngineStrengthMode.uciElo && elo == uciElo;
      },
      onSelected: (elo) {
        onStrengthModeChanged(EngineStrengthMode.uciElo);
        onUciEloChanged(elo);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCpLossEloStrengthTab(BuildContext context) {
    return _strengthValueColumns(
      columns: _cpLossEloColumns,
      columnWidth: 158,
      labelBuilder: (elo) => '$elo',
      isSelected: (elo) {
        return strengthMode == EngineStrengthMode.cpLossElo && elo == cpLossElo;
      },
      onSelected: (elo) {
        onStrengthModeChanged(EngineStrengthMode.cpLossElo);
        onCpLossEloChanged(elo);
        Navigator.pop(context);
      },
    );
  }

  Widget _strengthValueColumns({
    required List<List<int>> columns,
    required double columnWidth,
    required String Function(int value) labelBuilder,
    required bool Function(int value) isSelected,
    required ValueChanged<int> onSelected,
  }) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((columnValues) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: columnWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: columnValues.map((value) {
                      return _strengthValueButton(
                        isSelected: isSelected(value),
                        label: labelBuilder(value),
                        onPressed: () => onSelected(value),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _strengthValueButton({
    required bool isSelected,
    required String label,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: _dialogAccentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        ),
        child: Text(isSelected ? '✓ $label' : label),
      ),
    );
  }

  Future<void> _showCpLossUciSwitchMoveDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text(
            'UCI_ELO ab Zug',
            style: _dialogTitleTextStyle,
          ),
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
          title: const Text(
            'Eröffnung auswählen',
            style: _dialogTitleTextStyle,
          ),
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
          title: const Text(
            'Persönlichkeit auswählen',
            style: _dialogTitleTextStyle,
          ),
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
          title: const Text(
            'Kandidatenzüge auswählen',
            style: _dialogTitleTextStyle,
          ),
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

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () {
                              onPersonaCandidateCountChanged(candidateCount);
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: _dialogAccentBlue,
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
        child: DefaultTextStyle.merge(
          style: _dialogSelectableTextStyle,
          child: IconTheme(
            data: const IconThemeData(color: _dialogAccentBlue),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalityEnabled = botPersonality != BotPersonality.none;
    final cpLossEloEnabled = strengthMode == EngineStrengthMode.cpLossElo;
    final candidatesEnabled = personalityEnabled || cpLossEloEnabled;
    final normalControlsEnabled = !isBotThinking && !isAnalysisMode;

    final personalityButtonColor =
        effectiveBotPersonality.isAbstract ? Colors.orange : null;

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
              style: _analysisButtonStyle,
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
              onPressed:
                  normalControlsEnabled ? () => _showStrengthDialog(context) : null,
              child: Text(_strengthButtonText),
            ),
            ElevatedButton(
              onPressed: normalControlsEnabled && cpLossEloEnabled
                  ? () => _showCpLossUciSwitchMoveDialog(context)
                  : null,
              child: Text(_uciSwitchButtonText),
            ),
            ElevatedButton(
              onPressed:
                  normalControlsEnabled ? () => _showOpeningDialog(context) : null,
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

final ButtonStyle _analysisButtonStyle = ButtonStyle(
  foregroundColor: const WidgetStatePropertyAll<Color>(
    _analysisButtonForeground,
  ),
  iconColor: const WidgetStatePropertyAll<Color>(_analysisButtonForeground),
  mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return SystemMouseCursors.basic;
    }

    return SystemMouseCursors.click;
  }),
);

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
      final effectiveText =
          '${personality.label} (${effectiveBotPersonality.label})';

      return Text(effectiveText);
    }

    return Text(personality.label);
  }
}
