import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bot_opening_move.dart';
import '../../models/bot_profile.dart';
import '../../models/bot_personality.dart';
import '../../models/bot_personality_source.dart';
import '../../models/engine_strength_mode.dart';
import '../../models/fritz19_personality.dart';
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
    required this.effectiveBotOpeningMove,
    required this.selectedOpeningMoves,
    required this.botPersonalitySource,
    required this.effectiveBotPersonalitySource,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.fritz19Personality,
    required this.effectiveFritz19Personality,
    required this.selectedChessiversePersonalities,
    required this.selectedFritz19Personalities,
    required this.personaCandidateCount,
    required this.draftSkillLevel,
    required this.draftUciElo,
    required this.draftCpLossElo,
    required this.draftCpLossUciSwitchFullMoveNumber,
    required this.draftStrengthMode,
    required this.draftBotOpeningMove,
    required this.draftEffectiveBotOpeningMove,
    required this.draftSelectedOpeningMoves,
    required this.draftBotPersonalitySource,
    required this.draftEffectiveBotPersonalitySource,
    required this.draftBotPersonality,
    required this.draftEffectiveBotPersonality,
    required this.draftFritz19Personality,
    required this.draftEffectiveFritz19Personality,
    required this.draftSelectedChessiversePersonalities,
    required this.draftSelectedFritz19Personalities,
    required this.draftPersonaCandidateCount,
    required this.activeBotProfile,
    required this.draftBotProfile,
    required this.normalSettingsLockedByBotProfile,
    required this.onBotProfileSelected,
    required this.onBotProfileDisabled,
    required this.isBotThinking,
    required this.isAnalysisMode,
    required this.canToggleAnalysisMode,
    required this.canNavigateAnalysisBack,
    required this.canNavigateAnalysisForward,
    required this.onNewGame,
    required this.onRestart,
    required this.onToggleAnalysisMode,
    required this.onAnalysisBack,
    required this.onAnalysisForward,
    required this.onAnalysisBackToStart,
    required this.onAnalysisForwardToEnd,
    required this.onSkillLevelChanged,
    required this.onUciEloChanged,
    required this.onCpLossEloChanged,
    required this.onCpLossUciSwitchFullMoveNumberChanged,
    required this.onStrengthModeChanged,
    required this.onBotOpeningMoveChanged,
    required this.onOpeningMoveSelectionToggled,
    required this.onOpeningMoveSelectionCleared,
    required this.onBotPersonalityChanged,
    required this.onFritz19PersonalityChanged,
    required this.onChessiversePersonalitySelectionToggled,
    required this.onFritz19PersonalitySelectionToggled,
    required this.onPersonalitySelectionCleared,
    required this.onAllPersonalitiesRandomChanged,
    required this.onPersonaCandidateCountChanged,
    this.showPrimaryControls = true,
    this.showSecondaryControls = true,
    super.key,
  });

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final int cpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotOpeningMove effectiveBotOpeningMove;
  final List<BotOpeningMove> selectedOpeningMoves;
  final BotPersonalitySource botPersonalitySource;
  final BotPersonalitySource effectiveBotPersonalitySource;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final Fritz19Personality fritz19Personality;
  final Fritz19Personality effectiveFritz19Personality;
  final List<BotPersonality> selectedChessiversePersonalities;
  final List<Fritz19Personality> selectedFritz19Personalities;
  final int personaCandidateCount;

  final int draftSkillLevel;
  final int draftUciElo;
  final int draftCpLossElo;
  final int draftCpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode draftStrengthMode;
  final BotOpeningMove draftBotOpeningMove;
  final BotOpeningMove draftEffectiveBotOpeningMove;
  final List<BotOpeningMove> draftSelectedOpeningMoves;
  final BotPersonalitySource draftBotPersonalitySource;
  final BotPersonalitySource draftEffectiveBotPersonalitySource;
  final BotPersonality draftBotPersonality;
  final BotPersonality draftEffectiveBotPersonality;
  final Fritz19Personality draftFritz19Personality;
  final Fritz19Personality draftEffectiveFritz19Personality;
  final List<BotPersonality> draftSelectedChessiversePersonalities;
  final List<Fritz19Personality> draftSelectedFritz19Personalities;
  final int draftPersonaCandidateCount;

  final BotProfile? activeBotProfile;
  final BotProfile? draftBotProfile;
  final bool normalSettingsLockedByBotProfile;

  final bool isBotThinking;
  final bool isAnalysisMode;
  final bool canToggleAnalysisMode;
  final bool canNavigateAnalysisBack;
  final bool canNavigateAnalysisForward;

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;
  final VoidCallback onToggleAnalysisMode;
  final Future<void> Function() onAnalysisBack;
  final Future<void> Function() onAnalysisForward;
  final Future<void> Function() onAnalysisBackToStart;
  final Future<void> Function() onAnalysisForwardToEnd;

  final ValueChanged<int> onSkillLevelChanged;
  final ValueChanged<int> onUciEloChanged;
  final ValueChanged<int> onCpLossEloChanged;
  final ValueChanged<int> onCpLossUciSwitchFullMoveNumberChanged;
  final ValueChanged<EngineStrengthMode> onStrengthModeChanged;
  final ValueChanged<BotOpeningMove> onBotOpeningMoveChanged;
  final ValueChanged<BotOpeningMove> onOpeningMoveSelectionToggled;
  final VoidCallback onOpeningMoveSelectionCleared;
  final ValueChanged<BotPersonality> onBotPersonalityChanged;
  final ValueChanged<Fritz19Personality> onFritz19PersonalityChanged;
  final ValueChanged<BotPersonality> onChessiversePersonalitySelectionToggled;
  final ValueChanged<Fritz19Personality> onFritz19PersonalitySelectionToggled;
  final VoidCallback onPersonalitySelectionCleared;
  final VoidCallback onAllPersonalitiesRandomChanged;
  final ValueChanged<int> onPersonaCandidateCountChanged;
  final bool showPrimaryControls;
  final bool showSecondaryControls;
  final ValueChanged<BotProfile> onBotProfileSelected;
  final VoidCallback onBotProfileDisabled;

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

  String get _openingButtonText {
    if (botOpeningMove == BotOpeningMove.random) {
      return 'Zufällig: ${effectiveBotOpeningMove.label}';
    }

    return botOpeningMove.label;
  }

  String get _personalityButtonText {
    if (botPersonalitySource == BotPersonalitySource.random) {
      if (effectiveBotPersonalitySource == BotPersonalitySource.fritz19) {
        return 'Alles Zufällig: Fritz19 '
            '${effectiveFritz19Personality.label}';
      }

      return 'Alles Zufällig: ${effectiveBotPersonality.label}';
    }

    if (botPersonalitySource == BotPersonalitySource.fritz19) {
      if (fritz19Personality == Fritz19Personality.random) {
        return 'Fritz19 Zufällig: ${effectiveFritz19Personality.label}';
      }

      return 'Fritz19: ${fritz19Personality.label}';
    }

    if (botPersonality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      return 'Zufällig: ${effectiveBotPersonality.label}';
    }

    return botPersonality.label;
  }

  String get _candidateButtonText {
    return 'Kandidaten: $personaCandidateCount';
  }

  String get _botsButtonText {
    if (!normalSettingsLockedByBotProfile) {
      return 'Bots';
    }

    final profile = draftBotProfile ?? activeBotProfile;

    if (profile == null) {
      return 'Bots';
    }

    return 'Bots: ${profile.displayName}';
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

  List<List<BotOpeningMove>> get _openingColumns {
    final values = BotOpeningMove.realOpenings;
    final columns = <List<BotOpeningMove>>[];

    for (var i = 0; i < values.length; i += 10) {
      final end = (i + 10).clamp(0, values.length).toInt();
      columns.add(values.sublist(i, end));
    }

    return columns;
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
    switch (draftStrengthMode) {
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
        return draftStrengthMode == EngineStrengthMode.level &&
            level == draftSkillLevel;
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
        return draftStrengthMode == EngineStrengthMode.uciElo &&
            elo == draftUciElo;
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
        return draftStrengthMode == EngineStrengthMode.cpLossElo &&
            elo == draftCpLossElo;
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
    return SingleChildScrollView(
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
                    moveNumber == draftCpLossUciSwitchFullMoveNumber
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
    final localSelectedOpeningMoves = List<BotOpeningMove>.from(
      draftSelectedOpeningMoves,
    );
    var localBotOpeningMove = draftBotOpeningMove;

    void applyLocalOpeningSelection() {
      if (localSelectedOpeningMoves.isEmpty) {
        localBotOpeningMove = BotOpeningMove.none;
      } else if (localSelectedOpeningMoves.length == 1) {
        localBotOpeningMove = localSelectedOpeningMoves.first;
      } else {
        localBotOpeningMove = BotOpeningMove.random;
      }
    }

    bool isOpeningSelected(BotOpeningMove openingMove) {
      if (openingMove.isRealOpening) {
        if (localSelectedOpeningMoves.isNotEmpty) {
          return localSelectedOpeningMoves.contains(openingMove);
        }

        return localBotOpeningMove == openingMove;
      }

      return localSelectedOpeningMoves.isEmpty &&
          localBotOpeningMove == openingMove;
    }

    void clearLocalOpeningSelection() {
      localSelectedOpeningMoves.clear();
      localBotOpeningMove = BotOpeningMove.none;
    }

    void selectOtherOpening(BotOpeningMove openingMove) {
      localSelectedOpeningMoves.clear();
      localBotOpeningMove = openingMove;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildOpeningsTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clearSelectionButton(
                    isEnabled: localSelectedOpeningMoves.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalOpeningSelection);
                      onOpeningMoveSelectionCleared();
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _openingColumns.map((columnValues) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: columnValues.map((move) {
                                  return _selectableTextButton(
                                    isSelected: isOpeningSelected(move),
                                    label: move.label,
                                    onPressed: () {
                                      setDialogState(() {
                                        if (localSelectedOpeningMoves.isEmpty &&
                                            localBotOpeningMove.isRealOpening) {
                                          localSelectedOpeningMoves.add(
                                            localBotOpeningMove,
                                          );
                                        }

                                        if (localSelectedOpeningMoves.contains(
                                          move,
                                        )) {
                                          localSelectedOpeningMoves.remove(
                                            move,
                                          );
                                        } else {
                                          localSelectedOpeningMoves.add(move);
                                        }

                                        applyLocalOpeningSelection();
                                      });

                                      onOpeningMoveSelectionToggled(move);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }

            Widget buildOtherTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clearSelectionButton(
                    isEnabled: false,
                    onPressed: onOpeningMoveSelectionCleared,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _selectableTextButton(
                          isSelected: isOpeningSelected(BotOpeningMove.none),
                          label: 'Ohne Eröffnung',
                          onPressed: () {
                            setDialogState(() {
                              selectOtherOpening(BotOpeningMove.none);
                            });
                            onBotOpeningMoveChanged(BotOpeningMove.none);
                          },
                        ),
                        _selectableTextButton(
                          isSelected: isOpeningSelected(BotOpeningMove.random),
                          label: 'Zufällig',
                          onPressed: () {
                            setDialogState(() {
                              selectOtherOpening(BotOpeningMove.random);
                            });
                            onBotOpeningMoveChanged(BotOpeningMove.random);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                title: const Text(
                  'Eröffnung auswählen',
                  style: _dialogTitleTextStyle,
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                content: SizedBox(
                  width: 520,
                  height: 490,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TabBar(
                        labelColor: _dialogAccentBlue,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: _dialogAccentBlue,
                        tabs: [
                          Tab(text: 'Eröffnungen'),
                          Tab(text: 'Sonstiges'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            buildOpeningsTab(),
                            buildOtherTab(),
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
      },
    );
  }

  bool _isOpeningSelected(BotOpeningMove openingMove) {
    if (openingMove.isRealOpening) {
      if (selectedOpeningMoves.isNotEmpty) {
        return selectedOpeningMoves.contains(openingMove);
      }

      return botOpeningMove == openingMove;
    }

    return selectedOpeningMoves.isEmpty && botOpeningMove == openingMove;
  }

  void _handleOpeningSelected(BotOpeningMove openingMove) {
    if (openingMove.isRealOpening) {
      onOpeningMoveSelectionToggled(openingMove);
      return;
    }

    onBotOpeningMoveChanged(openingMove);
  }

  Future<void> _showPersonalityDialog(BuildContext context) async {
    var localSource = draftBotPersonalitySource;
    var localBotPersonality = draftBotPersonality;
    var localFritz19Personality = draftFritz19Personality;
    final localChessiversePersonalities = List<BotPersonality>.from(
      draftSelectedChessiversePersonalities,
    );
    final localFritz19Personalities = List<Fritz19Personality>.from(
      draftSelectedFritz19Personalities,
    );

    void clearLocalPersonalitySelection() {
      localSource = BotPersonalitySource.chessiverse;
      localBotPersonality = BotPersonality.none;
      localFritz19Personality = Fritz19Personality.allrounder;
      localChessiversePersonalities.clear();
      localFritz19Personalities.clear();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildChessiverseTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clearSelectionButton(
                    isEnabled:
                        localSource == BotPersonalitySource.chessiverse &&
                            localChessiversePersonalities.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalPersonalitySelection);
                      onPersonalitySelectionCleared();
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children:
                          BotPersonality.concretePersonalities.map((personality) {
                        final isSelected =
                            localChessiversePersonalities.isNotEmpty
                                ? localChessiversePersonalities.contains(
                                    personality,
                                  )
                                : localSource ==
                                        BotPersonalitySource.chessiverse &&
                                    localBotPersonality == personality;

                        return _selectableTextButton(
                          isSelected: isSelected,
                          label: personality.label,
                          onPressed: () {
                            setDialogState(() {
                              if (localSource !=
                                  BotPersonalitySource.chessiverse) {
                                localChessiversePersonalities.clear();
                              } else if (localChessiversePersonalities.isEmpty &&
                                  localBotPersonality.isConcretePersonality) {
                                localChessiversePersonalities.add(
                                  localBotPersonality,
                                );
                              }

                              if (localChessiversePersonalities.contains(
                                personality,
                              )) {
                                localChessiversePersonalities.remove(
                                  personality,
                                );
                              } else {
                                localChessiversePersonalities.add(personality);
                              }

                              localSource = BotPersonalitySource.chessiverse;
                              localFritz19Personalities.clear();

                              if (localChessiversePersonalities.isEmpty) {
                                localBotPersonality = BotPersonality.none;
                              } else if (localChessiversePersonalities.length ==
                                  1) {
                                localBotPersonality =
                                    localChessiversePersonalities.first;
                              } else {
                                localBotPersonality = BotPersonality.random;
                              }
                            });
                            onChessiversePersonalitySelectionToggled(
                              personality,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }

            Widget buildFritz19Tab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clearSelectionButton(
                    isEnabled: localSource == BotPersonalitySource.fritz19 &&
                        localFritz19Personalities.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalPersonalitySelection);
                      onPersonalitySelectionCleared();
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: Fritz19Personality.concretePersonalities
                          .map((personality) {
                        final isSelected = localFritz19Personalities.isNotEmpty
                            ? localFritz19Personalities.contains(personality)
                            : localSource == BotPersonalitySource.fritz19 &&
                                localFritz19Personality == personality;

                        return _selectableTextButton(
                          isSelected: isSelected,
                          label: personality.label,
                          onPressed: () {
                            setDialogState(() {
                              if (localSource != BotPersonalitySource.fritz19) {
                                localFritz19Personalities.clear();
                              } else if (localFritz19Personalities.isEmpty &&
                                  localFritz19Personality
                                      .isConcretePersonality) {
                                localFritz19Personalities.add(
                                  localFritz19Personality,
                                );
                              }

                              if (localFritz19Personalities.contains(
                                personality,
                              )) {
                                localFritz19Personalities.remove(personality);
                              } else {
                                localFritz19Personalities.add(personality);
                              }

                              localSource = BotPersonalitySource.fritz19;
                              localChessiversePersonalities.clear();

                              if (localFritz19Personalities.isEmpty) {
                                localSource = BotPersonalitySource.chessiverse;
                                localBotPersonality = BotPersonality.none;
                                localFritz19Personality =
                                    Fritz19Personality.allrounder;
                              } else if (localFritz19Personalities.length == 1) {
                                localFritz19Personality =
                                    localFritz19Personalities.first;
                              } else {
                                localFritz19Personality =
                                    Fritz19Personality.random;
                              }
                            });
                            onFritz19PersonalitySelectionToggled(personality);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }

            Widget buildOtherTab() {
              final options = <_OtherPersonalityOption>[
                _OtherPersonalityOption(
                  label: 'Ohne Persönlichkeit',
                  isSelected: localSource == BotPersonalitySource.chessiverse &&
                      localBotPersonality == BotPersonality.none,
                  onSelected: () {
                    setDialogState(clearLocalPersonalitySelection);
                    onBotPersonalityChanged(BotPersonality.none);
                  },
                ),
                _OtherPersonalityOption(
                  label: 'Chessiverse Zufällig',
                  isSelected: localSource == BotPersonalitySource.chessiverse &&
                      localBotPersonality == BotPersonality.random &&
                      localChessiversePersonalities.isEmpty,
                  onSelected: () {
                    setDialogState(() {
                      localSource = BotPersonalitySource.chessiverse;
                      localBotPersonality = BotPersonality.random;
                      localChessiversePersonalities.clear();
                      localFritz19Personalities.clear();
                    });
                    onBotPersonalityChanged(BotPersonality.random);
                  },
                ),
                _OtherPersonalityOption(
                  label: 'Fritz19 Zufällig',
                  isSelected: localSource == BotPersonalitySource.fritz19 &&
                      localFritz19Personality == Fritz19Personality.random &&
                      localFritz19Personalities.isEmpty,
                  onSelected: () {
                    setDialogState(() {
                      localSource = BotPersonalitySource.fritz19;
                      localFritz19Personality = Fritz19Personality.random;
                      localChessiversePersonalities.clear();
                      localFritz19Personalities.clear();
                    });
                    onFritz19PersonalityChanged(Fritz19Personality.random);
                  },
                ),
                _OtherPersonalityOption(
                  label: 'Alles Zufällig',
                  isSelected: localSource == BotPersonalitySource.random,
                  onSelected: () {
                    setDialogState(() {
                      localSource = BotPersonalitySource.random;
                      localChessiversePersonalities.clear();
                      localFritz19Personalities.clear();
                    });
                    onAllPersonalitiesRandomChanged();
                  },
                ),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clearSelectionButton(
                    isEnabled: false,
                    onPressed: onPersonalitySelectionCleared,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: options.map((option) {
                        return _selectableTextButton(
                          isSelected: option.isSelected,
                          label: option.label,
                          onPressed: option.onSelected,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: 3,
              child: AlertDialog(
                title: const Text(
                  'Persönlichkeit auswählen',
                  style: _dialogTitleTextStyle,
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                content: SizedBox(
                  width: 520,
                  height: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TabBar(
                        labelColor: _dialogAccentBlue,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: _dialogAccentBlue,
                        tabs: [
                          Tab(text: 'Chessiverse'),
                          Tab(text: 'Fritz19'),
                          Tab(text: 'Sonstiges'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            buildChessiverseTab(),
                            buildFritz19Tab(),
                            buildOtherTab(),
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
      },
    );
  }

  Widget _buildChessiversePersonalityTab(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildFritz19PersonalityTab(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildOtherPersonalityTab(BuildContext context) {
    return const SizedBox.shrink();
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
                            candidateCount == draftPersonaCandidateCount;

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

  Future<void> _showBotsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Bots auswählen',
            style: _dialogTitleTextStyle,
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          content: SizedBox(
            width: 560,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _selectableTextButton(
                  isSelected: !normalSettingsLockedByBotProfile,
                  label: 'Bots deaktivieren',
                  onPressed: () {
                    onBotProfileDisabled();
                    Navigator.pop(dialogContext);
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: BotProfile.maia3Profiles.map((profile) {
                      return _selectableTextButton(
                        isSelected: normalSettingsLockedByBotProfile &&
                            draftBotProfile?.id == profile.id,
                        label: profile.displayName,
                        onPressed: () {
                          onBotProfileSelected(profile);
                          Navigator.pop(dialogContext);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _clearSelectionButton({
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isEnabled
              ? _dialogAccentBlue
              : Colors.black.withAlpha(95),
          backgroundColor: isEnabled
              ? _dialogAccentBlue.withAlpha(24)
              : Colors.black.withAlpha(10),
          side: BorderSide(
            color: isEnabled
                ? _dialogAccentBlue.withAlpha(150)
                : Colors.black.withAlpha(28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Auswahl entfernen'),
      ),
    );
  }

  Widget _selectableTextButton({
    required bool isSelected,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? _dialogAccentBlue.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _dialogAccentBlue.withAlpha(120)
                : Colors.transparent,
          ),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: _dialogAccentBlue,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          child: Text(label),
        ),
      ),
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
    final personalityEnabled =
        botPersonalitySource != BotPersonalitySource.chessiverse ||
        botPersonality != BotPersonality.none ||
        selectedChessiversePersonalities.isNotEmpty ||
        selectedFritz19Personalities.isNotEmpty;
    final cpLossEloEnabled = strengthMode == EngineStrengthMode.cpLossElo;
    final candidatesEnabled = personalityEnabled || cpLossEloEnabled;
    final normalControlsEnabled = !isBotThinking && !isAnalysisMode;
    final settingsControlsEnabled =
        normalControlsEnabled && !normalSettingsLockedByBotProfile;

    final personalityButtonColor =
        effectiveBotPersonality.isAbstract ? Colors.orange : null;

    final sections = <Widget>[];

    if (showPrimaryControls) {
      sections.add(
        Wrap(
          alignment: WrapAlignment.center,
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
              onPressed: canToggleAnalysisMode ? onToggleAnalysisMode : null,
              style: _analysisButtonStyle,
              child: Text(_analysisButtonText),
            ),
            OutlinedButton.icon(
              onPressed: canNavigateAnalysisBack ? () => onAnalysisBack() : null,
              onLongPress:
                  canNavigateAnalysisBack ? () => onAnalysisBackToStart() : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Zurück'),
            ),
            OutlinedButton.icon(
              onPressed:
                  canNavigateAnalysisForward ? () => onAnalysisForward() : null,
              onLongPress: canNavigateAnalysisForward
                  ? () => onAnalysisForwardToEnd()
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Vor'),
            ),
          ],
        ),
      );
    }

    if (showSecondaryControls) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 16));
      }
      sections.add(
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed:
                  settingsControlsEnabled ? () => _showStrengthDialog(context) : null,
              child: Text(_strengthButtonText),
            ),
            ElevatedButton(
              onPressed: settingsControlsEnabled && cpLossEloEnabled
                  ? () => _showCpLossUciSwitchMoveDialog(context)
                  : null,
              child: Text(_uciSwitchButtonText),
            ),
            ElevatedButton(
              onPressed:
                  normalControlsEnabled ? () => _showOpeningDialog(context) : null,
              child: Text(_openingButtonText),
            ),
            ElevatedButton(
              onPressed: settingsControlsEnabled
                  ? () => _showPersonalityDialog(context)
                  : null,
              child: Text(
                _personalityButtonText,
                style: TextStyle(color: personalityButtonColor),
              ),
            ),
            ElevatedButton(
              onPressed: settingsControlsEnabled && candidatesEnabled
                  ? () => _showCandidateDialog(context)
                  : null,
              child: Text(_candidateButtonText),
            ),
            ElevatedButton.icon(
              onPressed:
                  normalControlsEnabled ? () => _showBotsDialog(context) : null,
              icon: const Icon(Icons.smart_toy),
              label: Text(_botsButtonText),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

final ButtonStyle _analysisButtonStyle = ButtonStyle(
  foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return const Color(0xFF8D95A3);
    }

    return _analysisButtonForeground;
  }),
  iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return const Color(0xFF8D95A3);
    }

    return _analysisButtonForeground;
  }),
  mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return SystemMouseCursors.basic;
    }

    return SystemMouseCursors.click;
  }),
);

class _EmptyFritz19PersonalityTab extends StatelessWidget {
  const _EmptyFritz19PersonalityTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Noch keine Fritz19-Persönlichkeiten',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black54,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OtherPersonalityOption {
  const _OtherPersonalityOption({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
}

class _PersonalityDialogLabel extends StatelessWidget {
  const _PersonalityDialogLabel({
    required this.personality,
    required this.selectedPersonality,
    required this.source,
    required this.effectiveBotPersonality,
  });

  final BotPersonality personality;
  final BotPersonality selectedPersonality;
  final BotPersonalitySource source;
  final BotPersonality effectiveBotPersonality;

  @override
  Widget build(BuildContext context) {
    final isSelected =
        source == BotPersonalitySource.chessiverse &&
        personality == selectedPersonality;

    return Text(isSelected ? '✓ ${personality.label}' : personality.label);
  }
}
