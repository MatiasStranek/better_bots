import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_profile.dart';
import '../../../models/bot_personality.dart';
import '../../../models/bot_personality_source.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/fritz19_personality.dart';
import '../../../models/player_side.dart';
import 'mobile_picker_sheet.dart';

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
  final ValueChanged<BotProfile> onBotProfileSelected;
  final VoidCallback onBotProfileDisabled;

  final VoidCallback onClose;
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
      return 'Bots deaktiviert';
    }

    final profile = draftBotProfile ?? activeBotProfile;

    if (profile == null) {
      return 'Bots deaktiviert';
    }

    return profile.displayName;
  }

  List<int> get _levelValues {
    return List.generate(21, (index) => index);
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

  /// Baut ein an den Inhalt angepasstes Chip-Raster (kein festes
  /// Spalten-Layout mehr, keine horizontale Scroll-Notwendigkeit).
  Widget _buildChipGrid<T>({
    required List<T> values,
    required String Function(T value) labelBuilder,
    required bool Function(T value) isSelected,
    required ValueChanged<T> onSelected,
    bool dense = false,
  }) {
    return MobilePickerChipGrid(
      children: [
        for (final value in values)
          MobilePickerChip(
            label: labelBuilder(value),
            isSelected: isSelected(value),
            dense: dense,
            onPressed: () => onSelected(value),
          ),
      ],
    );
  }

  Future<void> _showStrengthDialog(BuildContext context) async {
    var tabIndex = _strengthDialogInitialTabIndex;

    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return MobilePickerSheet(
              title: 'Spielstärke',
              tabLabels: const ['Level', 'UCI_ELO', 'CP_Loss'],
              currentTabIndex: tabIndex,
              onTabChanged: (index) => setSheetState(() => tabIndex = index),
              tabContents: [
                _buildChipGrid<int>(
                  values: _levelValues,
                  labelBuilder: (level) => 'Level $level',
                  dense: true,
                  isSelected: (level) {
                    return draftStrengthMode == EngineStrengthMode.level &&
                        level == draftSkillLevel;
                  },
                  onSelected: (level) {
                    onStrengthModeChanged(EngineStrengthMode.level);
                    onSkillLevelChanged(level);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _buildChipGrid<int>(
                  values: _eloValues,
                  labelBuilder: (elo) => '$elo',
                  dense: true,
                  isSelected: (elo) {
                    return draftStrengthMode == EngineStrengthMode.uciElo &&
                        elo == draftUciElo;
                  },
                  onSelected: (elo) {
                    onStrengthModeChanged(EngineStrengthMode.uciElo);
                    onUciEloChanged(elo);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _buildChipGrid<int>(
                  values: _cpLossEloValues,
                  labelBuilder: (elo) => '$elo',
                  dense: true,
                  isSelected: (elo) {
                    return draftStrengthMode == EngineStrengthMode.cpLossElo &&
                        elo == draftCpLossElo;
                  },
                  onSelected: (elo) {
                    onStrengthModeChanged(EngineStrengthMode.cpLossElo);
                    onCpLossEloChanged(elo);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCpLossUciSwitchMoveDialog(BuildContext context) async {
    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return MobilePickerSheet(
          title: 'UCI_ELO ab Zug',
          tabLabels: const ['Zug'],
          tabContents: [
            _buildChipGrid<int>(
              values: _cpLossUciSwitchMoveValues,
              labelBuilder: (moveNumber) => 'Zug $moveNumber',
              isSelected: (moveNumber) {
                return moveNumber == draftCpLossUciSwitchFullMoveNumber;
              },
              onSelected: (moveNumber) {
                onCpLossUciSwitchFullMoveNumberChanged(moveNumber);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOpeningDialog(BuildContext context) async {
    final localSelectedOpeningMoves = List<BotOpeningMove>.from(
      draftSelectedOpeningMoves,
    );
    var localBotOpeningMove = draftBotOpeningMove;
    var tabIndex = 0;

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

    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final openingsTab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePickerClearButton(
                  isEnabled: localSelectedOpeningMoves.length >= 2,
                  onPressed: () {
                    setSheetState(clearLocalOpeningSelection);
                    onOpeningMoveSelectionCleared();
                  },
                ),
                const SizedBox(height: 12),
                _buildChipGrid<BotOpeningMove>(
                  values: BotOpeningMove.realOpenings,
                  labelBuilder: (move) => move.label,
                  dense: true,
                  isSelected: isOpeningSelected,
                  onSelected: (openingMove) {
                    setSheetState(() {
                      if (localSelectedOpeningMoves.isEmpty &&
                          localBotOpeningMove.isRealOpening) {
                        localSelectedOpeningMoves.add(localBotOpeningMove);
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
              ],
            );

            final otherTab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePickerClearButton(
                  isEnabled: false,
                  onPressed: onOpeningMoveSelectionCleared,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: MobilePickerChip(
                    label: 'Ohne Eröffnung',
                    isSelected: isOpeningSelected(BotOpeningMove.none),
                    onPressed: () {
                      setSheetState(() {
                        selectOtherOpening(BotOpeningMove.none);
                      });
                      onBotOpeningMoveChanged(BotOpeningMove.none);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: MobilePickerChip(
                    label: 'Zufällig',
                    isSelected: isOpeningSelected(BotOpeningMove.random),
                    onPressed: () {
                      setSheetState(() {
                        selectOtherOpening(BotOpeningMove.random);
                      });
                      onBotOpeningMoveChanged(BotOpeningMove.random);
                    },
                  ),
                ),
              ],
            );

            return MobilePickerSheet(
              title: 'Eröffnung auswählen',
              tabLabels: const ['Eröffnungen', 'Sonstiges'],
              currentTabIndex: tabIndex,
              onTabChanged: (index) => setSheetState(() => tabIndex = index),
              tabContents: [openingsTab, otherTab],
            );
          },
        );
      },
    );
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
    var tabIndex = 0;

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

    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final chessiverseTab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePickerClearButton(
                  isEnabled:
                      localSource == BotPersonalitySource.chessiverse &&
                      localChessiversePersonalities.length >= 2,
                  onPressed: () {
                    setSheetState(clearLocalPersonalitySelection);
                    onPersonalitySelectionCleared();
                  },
                ),
                const SizedBox(height: 12),
                _buildChipGrid<BotPersonality>(
                  values: BotPersonality.concretePersonalities,
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
                    setSheetState(() {
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
              ],
            );

            final fritz19Tab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePickerClearButton(
                  isEnabled:
                      localSource == BotPersonalitySource.fritz19 &&
                      localFritz19Personalities.length >= 2,
                  onPressed: () {
                    setSheetState(clearLocalPersonalitySelection);
                    onPersonalitySelectionCleared();
                  },
                ),
                const SizedBox(height: 12),
                _buildChipGrid<Fritz19Personality>(
                  values: Fritz19Personality.concretePersonalities,
                  labelBuilder: (personality) => personality.label,
                  isSelected: (personality) {
                    if (localFritz19Personalities.isNotEmpty) {
                      return localFritz19Personalities.contains(personality);
                    }

                    return localSource == BotPersonalitySource.fritz19 &&
                        localFritz19Personality == personality;
                  },
                  onSelected: (personality) {
                    setSheetState(() {
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
              ],
            );

            final otherOptions = <_OtherPersonalityOption>[
              _OtherPersonalityOption(
                label: 'Ohne Persönlichkeit',
                isSelected: localSource == BotPersonalitySource.chessiverse &&
                    localBotPersonality == BotPersonality.none,
                onSelected: () {
                  setSheetState(clearLocalPersonalitySelection);
                  onBotPersonalityChanged(BotPersonality.none);
                },
              ),
              _OtherPersonalityOption(
                label: 'Chessiverse Zufällig',
                isSelected: localSource == BotPersonalitySource.chessiverse &&
                    localBotPersonality == BotPersonality.random &&
                    localChessiversePersonalities.isEmpty,
                onSelected: () {
                  setSheetState(() {
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
                  setSheetState(() {
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
                  setSheetState(() {
                    localSource = BotPersonalitySource.random;
                    localChessiversePersonalities.clear();
                    localFritz19Personalities.clear();
                  });
                  onAllPersonalitiesRandomChanged();
                },
              ),
            ];

            final otherTab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePickerClearButton(
                  isEnabled: false,
                  onPressed: onPersonalitySelectionCleared,
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < otherOptions.length; index++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: MobilePickerChip(
                      label: otherOptions[index].label,
                      isSelected: otherOptions[index].isSelected,
                      onPressed: otherOptions[index].onSelected,
                    ),
                  ),
                  if (index < otherOptions.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            );

            return MobilePickerSheet(
              title: 'Persönlichkeit auswählen',
              tabLabels: const ['Chessiverse', 'Fritz19', 'Sonstiges'],
              currentTabIndex: tabIndex,
              onTabChanged: (index) => setSheetState(() => tabIndex = index),
              tabContents: [chessiverseTab, fritz19Tab, otherTab],
            );
          },
        );
      },
    );
  }

  Future<void> _showCandidateDialog(BuildContext context) async {
    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return MobilePickerSheet(
          title: 'Kandidatenzüge auswählen',
          tabLabels: const ['Kandidaten'],
          tabContents: [
            _buildChipGrid<int>(
              values: _candidateValues,
              labelBuilder: (candidateCount) => '$candidateCount',
              dense: true,
              isSelected: (candidateCount) {
                return candidateCount == draftPersonaCandidateCount;
              },
              onSelected: (candidateCount) {
                onPersonaCandidateCountChanged(candidateCount);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBotsDialog(BuildContext context) async {
    await showMobilePickerSheet(
      context: context,
      builder: (sheetContext) {
        return MobilePickerSheet(
          title: 'Bots',
          tabLabels: const ['Bots'],
          showSingleTab: true,
          tabContents: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: MobilePickerChip(
                    label: 'Bots deaktivieren',
                    isSelected: !normalSettingsLockedByBotProfile,
                    onPressed: () {
                      onBotProfileDisabled();
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
                const SizedBox(height: 14),
                MobilePickerChipGrid(
                  children: BotProfile.maia3Profiles.map((profile) {
                    return MobilePickerChip(
                      label: profile.displayName,
                      isSelected: normalSettingsLockedByBotProfile &&
                          draftBotProfile?.id == profile.id,
                      onPressed: () {
                        onBotProfileSelected(profile);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
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
    final settingsControlsEnabled = isEnabled && !normalSettingsLockedByBotProfile;

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 18, 18),
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
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SideMenuButton(
                          icon: Icons.speed,
                          label: 'Spielstärke',
                          value: _strengthButtonText,
                          onTap: () => _showStrengthDialog(context),
                          isEnabled: settingsControlsEnabled,
                          isHighlighted: true,
                        ),
                        _SideMenuButton(
                          icon: Icons.call_split,
                          label: 'Eröffnung',
                          value: _openingButtonText,
                          onTap: () => _showOpeningDialog(context),
                          isEnabled: settingsControlsEnabled,
                        ),
                        _SideMenuButton(
                          icon: Icons.psychology,
                          label: 'Persönlichkeit',
                          value: _personalityButtonText,
                          onTap: () => _showPersonalityDialog(context),
                          isEnabled: settingsControlsEnabled,
                        ),
                        _SideMenuButton(
                          icon: Icons.list,
                          label: 'Kandidaten',
                          value: _candidateButtonText,
                          onTap: () => _showCandidateDialog(context),
                          isEnabled: settingsControlsEnabled && candidatesEnabled,
                        ),
                        _SideMenuButton(
                          icon: Icons.smart_toy,
                          label: 'Bots',
                          value: _botsButtonText,
                          onTap: () => _showBotsDialog(context),
                          isEnabled: isEnabled,
                        ),
                        _SideMenuButton(
                          icon: Icons.swap_horiz,
                          label: 'UCI_ELO Switch',
                          value: _uciSwitchButtonText,
                          onTap: () => _showCpLossUciSwitchMoveDialog(context),
                          isEnabled: settingsControlsEnabled && cpLossEloEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
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

class _EmptyBotsTab extends StatelessWidget {
  const _EmptyBotsTab();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Icon(
            Icons.smart_toy,
            size: 54,
            color: kPickerAccentColor.withAlpha(190),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bots',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hier können später einzelne Bots ausgewählt werden.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

