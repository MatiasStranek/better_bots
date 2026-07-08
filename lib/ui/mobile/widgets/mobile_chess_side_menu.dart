import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/bot_personality_source.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/fritz19_personality.dart';
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
    required this.onNewGame,
    required this.onRestart,
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

  final ValueChanged<PlayerSide> onNewGame;
  final VoidCallback onRestart;

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

  List<List<int>> get _levelColumns {
    return _columnsFromValues(List.generate(21, (index) => index), 10);
  }

  List<List<int>> get _uciEloColumns {
    return _columnsFromValues(_eloValues, 10);
  }

  List<List<int>> get _cpLossEloColumns {
    return _columnsFromValues(_cpLossEloValues, 10);
  }

  List<List<int>> get _candidateColumns {
    return _columnsFromValues(_candidateValues, 10);
  }

  List<List<BotOpeningMove>> get _openingColumns {
    return _columnsFromValues(BotOpeningMove.realOpenings, 7);
  }

  List<List<BotPersonality>> get _personalityColumns {
    return _columnsFromValues(BotPersonality.concretePersonalities, 10);
  }

  List<List<Fritz19Personality>> get _fritz19PersonalityColumns {
    return _columnsFromValues(Fritz19Personality.concretePersonalities, 10);
  }

  List<List<T>> _columnsFromValues<T>(
    List<T> values,
    int entriesPerColumn,
  ) {
    final columns = <List<T>>[];

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
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final dialogWidth =
            (screenSize.width - 32).clamp(320.0, 430.0).toDouble();
        final dialogHeight =
            (screenSize.height * 0.72).clamp(470.0, 620.0).toDouble();

        return DefaultTabController(
          initialIndex: _strengthDialogInitialTabIndex,
          length: 3,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            title: const Text('Spielstärke'),
            contentPadding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: _accentColor,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: _accentColor,
                    tabs: [
                      Tab(text: 'Level'),
                      Tab(text: 'UCI_ELO'),
                      Tab(text: 'CP_Loss'),
                    ],
                  ),
                  const SizedBox(height: 12),
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
    return _choiceColumns(
      columns: _levelColumns,
      labelBuilder: (level) => 'Level $level',
      isSelected: (level) {
        return strengthMode == EngineStrengthMode.level && level == skillLevel;
      },
      onSelected: (level) {
        onStrengthModeChanged(EngineStrengthMode.level);
        onSkillLevelChanged(level);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildUciEloStrengthTab(BuildContext context) {
    return _choiceColumns(
      columns: _uciEloColumns,
      labelBuilder: (elo) => '$elo',
      isSelected: (elo) {
        return strengthMode == EngineStrengthMode.uciElo && elo == uciElo;
      },
      onSelected: (elo) {
        onStrengthModeChanged(EngineStrengthMode.uciElo);
        onUciEloChanged(elo);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildCpLossEloStrengthTab(BuildContext context) {
    return _choiceColumns(
      columns: _cpLossEloColumns,
      labelBuilder: (elo) => '$elo',
      isSelected: (elo) {
        return strengthMode == EngineStrengthMode.cpLossElo && elo == cpLossElo;
      },
      onSelected: (elo) {
        onStrengthModeChanged(EngineStrengthMode.cpLossElo);
        onCpLossEloChanged(elo);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _choiceColumns({
    required List<List<int>> columns,
    required String Function(int value) labelBuilder,
    required bool Function(int value) isSelected,
    required ValueChanged<int> onSelected,
    double columnWidth = 96,
  }) {
    return _scrollableChoiceColumns<int>(
      columns: columns,
      columnWidth: columnWidth,
      labelBuilder: labelBuilder,
      isSelected: isSelected,
      onSelected: onSelected,
    );
  }

  Widget _objectChoiceColumns<T>({
    required List<List<T>> columns,
    required String Function(T value) labelBuilder,
    required bool Function(T value) isSelected,
    required ValueChanged<T> onSelected,
    double columnWidth = 126,
  }) {
    return _scrollableChoiceColumns<T>(
      columns: columns,
      columnWidth: columnWidth,
      labelBuilder: labelBuilder,
      isSelected: isSelected,
      onSelected: onSelected,
    );
  }

  Widget _scrollableChoiceColumns<T>({
    required List<List<T>> columns,
    required String Function(T value) labelBuilder,
    required bool Function(T value) isSelected,
    required ValueChanged<T> onSelected,
    required double columnWidth,
    double buttonHeight = 38,
    double bottomSpacing = 8,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var columnIndex = 0;
                      columnIndex < columns.length;
                      columnIndex++) ...[
                    SizedBox(
                      width: columnWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final value in columns[columnIndex])
                            Padding(
                              padding: EdgeInsets.only(bottom: bottomSpacing),
                              child: _DialogChoiceBox(
                                label: labelBuilder(value),
                                isSelected: isSelected(value),
                                height: buttonHeight,
                                onPressed: () => onSelected(value),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (columnIndex < columns.length - 1)
                      const SizedBox(width: 10),
                  ],
                ],
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
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final dialogWidth =
            (screenSize.width - 32).clamp(320.0, 430.0).toDouble();
        final dialogHeight =
            (screenSize.height * 0.42).clamp(250.0, 380.0).toDouble();

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Text('UCI_ELO ab Zug'),
          contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: _choiceColumns(
              columns: _columnsFromValues(_cpLossUciSwitchMoveValues, 10),
              columnWidth: 118,
              labelBuilder: (moveNumber) => 'Zug $moveNumber',
              isSelected: (moveNumber) {
                return moveNumber == cpLossUciSwitchFullMoveNumber;
              },
              onSelected: (moveNumber) {
                onCpLossUciSwitchFullMoveNumberChanged(moveNumber);
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showOpeningDialog(BuildContext context) async {
    final localSelectedOpeningMoves = List<BotOpeningMove>.from(
      selectedOpeningMoves,
    );
    var localBotOpeningMove = botOpeningMove;

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
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final dialogWidth =
            (screenSize.width - 32).clamp(320.0, 430.0).toDouble();
        final dialogHeight =
            (screenSize.height * 0.74 + 100).clamp(530.0, 780.0).toDouble();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildOpeningsTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClearSelectionButton(
                    isEnabled: localSelectedOpeningMoves.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalOpeningSelection);
                      onOpeningMoveSelectionCleared();
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _openingChoiceColumns(
                      columns: _openingColumns,
                      labelBuilder: (move) => move.label,
                      isSelected: isOpeningSelected,
                      onSelected: (openingMove) {
                        setDialogState(() {
                          if (localSelectedOpeningMoves.isEmpty &&
                              localBotOpeningMove.isRealOpening) {
                            localSelectedOpeningMoves.add(
                              localBotOpeningMove,
                            );
                          }

                          if (localSelectedOpeningMoves.contains(openingMove)) {
                            localSelectedOpeningMoves.remove(openingMove);
                          } else {
                            localSelectedOpeningMoves.add(openingMove);
                          }

                          applyLocalOpeningSelection();
                        });

                        onOpeningMoveSelectionToggled(openingMove);
                      },
                    ),
                  ),
                ],
              );
            }

            Widget buildOtherTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClearSelectionButton(
                    isEnabled: false,
                    onPressed: onOpeningMoveSelectionCleared,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DialogChoiceBox(
                            label: 'Ohne Eröffnung',
                            isSelected: isOpeningSelected(
                              BotOpeningMove.none,
                            ),
                            height: 36,
                            onPressed: () {
                              setDialogState(() {
                                selectOtherOpening(BotOpeningMove.none);
                              });
                              onBotOpeningMoveChanged(BotOpeningMove.none);
                            },
                          ),
                          const SizedBox(height: 8),
                          _DialogChoiceBox(
                            label: 'Zufällig',
                            isSelected: isOpeningSelected(
                              BotOpeningMove.random,
                            ),
                            height: 36,
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
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                title: const Text('Eröffnung auswählen'),
                contentPadding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                content: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TabBar(
                        labelColor: _accentColor,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: _accentColor,
                        tabs: [
                          Tab(text: 'Eröffnungen'),
                          Tab(text: 'Sonstiges'),
                        ],
                      ),
                      const SizedBox(height: 12),
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

  Widget _openingChoiceColumns({
    required List<List<BotOpeningMove>> columns,
    required String Function(BotOpeningMove value) labelBuilder,
    required bool Function(BotOpeningMove value) isSelected,
    required ValueChanged<BotOpeningMove> onSelected,
  }) {
    return _scrollableChoiceColumns<BotOpeningMove>(
      columns: columns,
      columnWidth: 118,
      buttonHeight: 32,
      bottomSpacing: 5,
      labelBuilder: labelBuilder,
      isSelected: isSelected,
      onSelected: onSelected,
    );
  }

  Future<void> _showPersonalityDialog(BuildContext context) async {
    var localSource = botPersonalitySource;
    var localBotPersonality = botPersonality;
    var localFritz19Personality = fritz19Personality;
    final localChessiversePersonalities = List<BotPersonality>.from(
      selectedChessiversePersonalities,
    );
    final localFritz19Personalities = List<Fritz19Personality>.from(
      selectedFritz19Personalities,
    );

    void applyLocalChessiverseSelection() {
      localSource = BotPersonalitySource.chessiverse;
      localFritz19Personalities.clear();

      if (localChessiversePersonalities.isEmpty) {
        localBotPersonality = BotPersonality.none;
      } else if (localChessiversePersonalities.length == 1) {
        localBotPersonality = localChessiversePersonalities.first;
      } else {
        localBotPersonality = BotPersonality.random;
      }
    }

    void applyLocalFritz19Selection() {
      localSource = BotPersonalitySource.fritz19;
      localChessiversePersonalities.clear();

      if (localFritz19Personalities.isEmpty) {
        localSource = BotPersonalitySource.chessiverse;
        localBotPersonality = BotPersonality.none;
        localFritz19Personality = Fritz19Personality.allrounder;
      } else if (localFritz19Personalities.length == 1) {
        localFritz19Personality = localFritz19Personalities.first;
      } else {
        localFritz19Personality = Fritz19Personality.random;
      }
    }

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
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final dialogWidth =
            (screenSize.width - 32).clamp(320.0, 430.0).toDouble();
        final dialogHeight =
            (screenSize.height * 0.62).clamp(360.0, 540.0).toDouble();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildChessiverseTab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClearSelectionButton(
                    isEnabled:
                        localSource == BotPersonalitySource.chessiverse &&
                            localChessiversePersonalities.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalPersonalitySelection);
                      onPersonalitySelectionCleared();
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _objectChoiceColumns<BotPersonality>(
                      columns: _personalityColumns,
                      columnWidth: 150,
                      labelBuilder: (personality) => personality.label,
                      isSelected: (personality) {
                        if (localChessiversePersonalities.isNotEmpty) {
                          return localChessiversePersonalities.contains(
                            personality,
                          );
                        }

                        return localSource == BotPersonalitySource.chessiverse &&
                            localBotPersonality == personality;
                      },
                      onSelected: (personality) {
                        setDialogState(() {
                          if (localSource != BotPersonalitySource.chessiverse) {
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
                            localChessiversePersonalities.remove(personality);
                          } else {
                            localChessiversePersonalities.add(personality);
                          }

                          applyLocalChessiverseSelection();
                        });
                        onChessiversePersonalitySelectionToggled(personality);
                      },
                    ),
                  ),
                ],
              );
            }

            Widget buildFritz19Tab() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClearSelectionButton(
                    isEnabled: localSource == BotPersonalitySource.fritz19 &&
                        localFritz19Personalities.length >= 2,
                    onPressed: () {
                      setDialogState(clearLocalPersonalitySelection);
                      onPersonalitySelectionCleared();
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _objectChoiceColumns<Fritz19Personality>(
                      columns: _fritz19PersonalityColumns,
                      columnWidth: 150,
                      labelBuilder: (personality) => personality.label,
                      isSelected: (personality) {
                        if (localFritz19Personalities.isNotEmpty) {
                          return localFritz19Personalities.contains(
                            personality,
                          );
                        }

                        return localSource == BotPersonalitySource.fritz19 &&
                            localFritz19Personality == personality;
                      },
                      onSelected: (personality) {
                        setDialogState(() {
                          if (localSource != BotPersonalitySource.fritz19) {
                            localFritz19Personalities.clear();
                          } else if (localFritz19Personalities.isEmpty &&
                              localFritz19Personality.isConcretePersonality) {
                            localFritz19Personalities.add(
                              localFritz19Personality,
                            );
                          }

                          if (localFritz19Personalities.contains(personality)) {
                            localFritz19Personalities.remove(personality);
                          } else {
                            localFritz19Personalities.add(personality);
                          }

                          applyLocalFritz19Selection();
                        });
                        onFritz19PersonalitySelectionToggled(personality);
                      },
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
                  _ClearSelectionButton(
                    isEnabled: false,
                    onPressed: onPersonalitySelectionCleared,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var index = 0; index < options.length; index++)
                            ...[
                              _DialogChoiceBox(
                                label: options[index].label,
                                isSelected: options[index].isSelected,
                                onPressed: options[index].onSelected,
                              ),
                              if (index < options.length - 1)
                                const SizedBox(height: 8),
                            ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: 3,
              child: AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                title: const Text('Persönlichkeit auswählen'),
                contentPadding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                content: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: _accentColor,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: _accentColor,
                        tabs: [
                          Tab(text: 'Chessiverse'),
                          Tab(text: 'Fritz19'),
                          Tab(text: 'Sonstiges'),
                        ],
                      ),
                      const SizedBox(height: 12),
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
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final dialogWidth =
            (screenSize.width - 32).clamp(320.0, 430.0).toDouble();
        final dialogHeight =
            (screenSize.height * 0.68).clamp(430.0, 600.0).toDouble();

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          title: const Text('Kandidatenzüge auswählen'),
          contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: _choiceColumns(
              columns: _candidateColumns,
              columnWidth: 96,
              labelBuilder: (candidateCount) => '$candidateCount',
              isSelected: (candidateCount) {
                return candidateCount == personaCandidateCount;
              },
              onSelected: (candidateCount) {
                onPersonaCandidateCountChanged(candidateCount);
                Navigator.of(dialogContext).pop();
              },
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
    final personalityEnabled =
        botPersonalitySource != BotPersonalitySource.chessiverse ||
        botPersonality != BotPersonality.none ||
        selectedChessiversePersonalities.isNotEmpty ||
        selectedFritz19Personalities.isNotEmpty;
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
                  icon: Icons.circle,
                  label: 'Neue Partie Weiß',
                  value: 'Du spielst Weiß',
                  onTap: () => _startNewGame(PlayerSide.white),
                  isEnabled: isEnabled,
                ),
                _SideMenuButton(
                  icon: Icons.circle_outlined,
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

class _ClearSelectionButton extends StatelessWidget {
  const _ClearSelectionButton({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isEnabled
              ? _SideMenuButton._accentColor
              : Colors.black.withAlpha(90),
          backgroundColor: isEnabled
              ? _SideMenuButton._accentColor.withAlpha(22)
              : Colors.black.withAlpha(10),
          side: BorderSide(
            color: isEnabled
                ? _SideMenuButton._accentColor.withAlpha(150)
                : Colors.black.withAlpha(28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Auswahl entfernen',
          style: TextStyle(fontWeight: FontWeight.w800),
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

class _DialogChoiceBox extends StatelessWidget {
  const _DialogChoiceBox({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.height = 38,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          foregroundColor: isSelected ? _SideMenuButton._accentColor : null,
          backgroundColor: isSelected
              ? _SideMenuButton._accentColor.withAlpha(24)
              : null,
          side: BorderSide(
            color: isSelected
                ? _SideMenuButton._accentColor.withAlpha(170)
                : Colors.black.withAlpha(42),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

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



