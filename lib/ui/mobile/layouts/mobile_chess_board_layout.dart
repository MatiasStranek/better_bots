import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../data/better_bots_database.dart';

import '../../../models/board_annotation.dart';
import '../../../models/board_highlights.dart';
import '../../../models/bot_opening_move.dart';
import '../../../models/bot_profile.dart';
import '../../../models/bot_personality.dart';
import '../../../models/bot_personality_source.dart';
import '../../../models/engine_analysis_line.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/fritz19_personality.dart';
import '../../../models/player_side.dart';
import '../widgets/chess_board/mobile_chess_board_view.dart';
import '../widgets/mobile_chess_action_bar.dart';
import '../widgets/mobile_chess_analysis_button.dart';
import '../widgets/mobile_chess_analysis_lines_bar.dart';
import '../widgets/mobile_chess_game_info_panel.dart';
import '../widgets/mobile_chess_move_strip.dart';
import '../widgets/mobile_chess_result_stats_panel.dart';
import '../widgets/mobile_chess_side_menu.dart';
import '../widgets/mobile_chess_status_header.dart';

class MobileChessBoardLayout extends StatefulWidget {
  const MobileChessBoardLayout({
    super.key,
    required this.statusText,
    required this.playerSideText,
    required this.pgnText,
    required this.fenText,
    required this.playerIsWhite,
    required this.pieceAt,
    required this.highlights,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
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
    required this.isAnalysisMode,
    required this.isAnalysisBranchActive,
    required this.analysisUsedDuringCurrentGame,
    required this.analysisLines,
    required this.trainingCounter,
    required this.canToggleAnalysisMode,
    required this.canNavigateAnalysisBack,
    required this.canNavigateAnalysisForward,
    required this.onToggleAnalysisMode,
    required this.onTrainingRestart,
    required this.onAnalysisBack,
    required this.onAnalysisForward,
    required this.onAnalysisBackToStart,
    required this.onAnalysisForwardToEnd,
    required this.annotationMarkedSquares,
    required this.annotationArrows,
    required this.onClearBoardAnnotations,
    required this.onToggleAnnotationSquare,
    required this.onToggleAnnotationArrow,
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
    this.controlsEnabled = true,
  });

  final String statusText;
  final String playerSideText;
  final String pgnText;
  final String fenText;

  final bool playerIsWhite;
  final chess.Piece? Function(String square) pieceAt;

  final BoardHighlights highlights;

  final bool Function(String square) canHumanMovePiece;
  final bool Function({required String from, required String to}) canMoveTo;

  final Future<void> Function(String square) onSquareTap;

  final Future<bool> Function({
    required String from,
    required String to,
    String? promotion,
  })
  onMove;

  final ValueChanged<String> onPieceDragStarted;
  final VoidCallback onPieceDragEnded;

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

  final bool isAnalysisMode;
  final bool isAnalysisBranchActive;
  final bool analysisUsedDuringCurrentGame;
  final List<EngineAnalysisLine> analysisLines;
  final TrainingCounterSnapshot trainingCounter;
  final bool canToggleAnalysisMode;
  final bool canNavigateAnalysisBack;
  final bool canNavigateAnalysisForward;
  final VoidCallback onToggleAnalysisMode;
  final VoidCallback onTrainingRestart;
  final Future<void> Function() onAnalysisBack;
  final Future<void> Function() onAnalysisForward;
  final Future<void> Function() onAnalysisBackToStart;
  final Future<void> Function() onAnalysisForwardToEnd;

  final Set<String> annotationMarkedSquares;
  final Set<BoardArrowAnnotation> annotationArrows;
  final VoidCallback onClearBoardAnnotations;
  final ValueChanged<String> onToggleAnnotationSquare;
  final ValueChanged<BoardArrowAnnotation> onToggleAnnotationArrow;

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

  final bool controlsEnabled;

  @override
  State<MobileChessBoardLayout> createState() => _MobileChessBoardLayoutState();
}

class _MobileChessBoardLayoutState extends State<MobileChessBoardLayout> {
  static const double _screenPadding = 16;
  static const double _statusHeaderHeight = 48;
  static const double _moveStripTop = 48;
  static const double _moveStripHeight = 54;
  static const double _resultStatsHeight = 70;
  static const double _analysisLinesBarHeight = 66;
  static const double _analysisLinesBarGap = 8;
  static const double _actionBarHeight = 64;
  static const double _analysisButtonSize = 52;
  static const double _analysisButtonGap = 8;
  static const double _analysisUseIndicatorHeight = 32;
  static const double _analysisUseIndicatorGap = 6;
  static const double _analysisIconVisualSize = 30;
  static const double _analysisIconGlyphTopCorrection = 3;
  static const double _gameInfoPanelHorizontalGap = 12;
  static const double _edgeSwipeWidth = 36;
  static const double _sideMenuWidthFactor = 0.72;
  static const double _swipeOpenThreshold = 54;
  static const double _swipeCloseThreshold = -54;

  bool _isSideMenuOpen = false;
  double _openSwipeDelta = 0;
  double _closeSwipeDelta = 0;

  void _openSideMenu() {
    if (_isSideMenuOpen) {
      return;
    }

    setState(() {
      _isSideMenuOpen = true;
    });
  }

  void _closeSideMenu() {
    if (!_isSideMenuOpen) {
      return;
    }

    setState(() {
      _isSideMenuOpen = false;
    });
  }

  void _toggleSideMenu() {
    setState(() {
      _isSideMenuOpen = !_isSideMenuOpen;
    });
  }

  void _handleOpenSwipeUpdate(DragUpdateDetails details) {
    _openSwipeDelta += details.delta.dx;

    if (_openSwipeDelta >= _swipeOpenThreshold) {
      _openSwipeDelta = 0;
      _openSideMenu();
    }
  }

  void _handleOpenSwipeEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx > 500) {
      _openSideMenu();
    }

    _openSwipeDelta = 0;
  }

  void _handleCloseSwipeUpdate(DragUpdateDetails details) {
    _closeSwipeDelta += details.delta.dx;

    if (_closeSwipeDelta <= _swipeCloseThreshold) {
      _closeSwipeDelta = 0;
      _closeSideMenu();
    }
  }

  void _handleCloseSwipeEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx < -500) {
      _closeSideMenu();
    }

    _closeSwipeDelta = 0;
  }

  Widget _buildClosedEdgeSwipeAreas({
    required double screenHeight,
    required double boardTop,
    required double boardBottom,
  }) {
    if (_isSideMenuOpen) {
      return const SizedBox.shrink();
    }

    final topStart = _moveStripTop + _moveStripHeight;
    final topHeight = math.max(0.0, boardTop - topStart);
    final safeBottom = math.max(0.0, screenHeight - _actionBarHeight);
    final bottomTop = math.min(boardBottom, safeBottom);
    final bottomHeight = math.max(0.0, safeBottom - bottomTop);

    return Stack(
      children: [
        if (topHeight > 0)
          Positioned(
            left: 0,
            top: topStart,
            width: _edgeSwipeWidth,
            height: topHeight,
            child: _EdgeSwipeDetector(
              onHorizontalDragUpdate: _handleOpenSwipeUpdate,
              onHorizontalDragEnd: _handleOpenSwipeEnd,
            ),
          ),
        if (bottomHeight > 0)
          Positioned(
            left: 0,
            top: bottomTop,
            width: _edgeSwipeWidth,
            height: bottomHeight,
            child: _EdgeSwipeDetector(
              onHorizontalDragUpdate: _handleOpenSwipeUpdate,
              onHorizontalDragEnd: _handleOpenSwipeEnd,
            ),
          ),
      ],
    );
  }

  double _analysisButtonTop({
    required double boardBottom,
    required double screenHeight,
  }) {
    final preferredTop = boardBottom + _analysisButtonGap;
    final maxTop =
        screenHeight - _actionBarHeight - _analysisButtonSize - _analysisButtonGap;

    return math.min(preferredTop, math.max(0.0, maxTop));
  }

  double _gameInfoPanelHeight({
    required double top,
    required double screenHeight,
  }) {
    final maxHeight =
        screenHeight - top - _actionBarHeight - _analysisButtonGap;

    return math.max(0.0, maxHeight);
  }

  double _topBetweenMoveStripAndBoard({
    required double boardTop,
    required double contentHeight,
  }) {
    const moveStripBottom = _moveStripTop + _moveStripHeight;
    final availableGap = boardTop - moveStripBottom - contentHeight;

    return moveStripBottom + math.max(0.0, availableGap / 2.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - (_screenPadding * 2);
        final boardSize = math.min(constraints.maxWidth, availableHeight);

        final boardTop = (constraints.maxHeight - boardSize) / 2;
        final boardBottom = boardTop + boardSize;
        final canShowActionBar = constraints.maxHeight >= _actionBarHeight;
        final sideMenuWidth = constraints.maxWidth * _sideMenuWidthFactor;
        final analysisButtonTop = _analysisButtonTop(
          boardBottom: boardBottom,
          screenHeight: constraints.maxHeight,
        );
        final gameInfoPanelTop =
            analysisButtonTop +
            ((_analysisButtonSize - _analysisIconVisualSize) / 2) +
            _analysisIconGlyphTopCorrection;
        final gameInfoPanelHeight = _gameInfoPanelHeight(
          top: gameInfoPanelTop,
          screenHeight: constraints.maxHeight,
        );
        final analysisUseIndicatorTop =
            analysisButtonTop + _analysisButtonSize + _analysisUseIndicatorGap;
        final canShowAnalysisUseIndicator =
            analysisUseIndicatorTop + _analysisUseIndicatorHeight <=
                constraints.maxHeight - _actionBarHeight - 4;
        final resultStatsTop = _topBetweenMoveStripAndBoard(
          boardTop: boardTop,
          contentHeight: _resultStatsHeight,
        );
        final analysisLinesBarTop = _topBetweenMoveStripAndBoard(
          boardTop: boardTop,
          contentHeight: _analysisLinesBarHeight,
        );

        return Stack(
          children: [
            Center(
              child: SizedBox.square(
                dimension: boardSize,
                child: MobileChessBoardView(
                  playerIsWhite: widget.playerIsWhite,
                  isAnalysisMode: widget.isAnalysisMode,
                  isAnalysisBranchActive: widget.isAnalysisBranchActive,
                  pieceAt: widget.pieceAt,
                  highlights: widget.highlights,
                  canHumanMovePiece: widget.canHumanMovePiece,
                  canMoveTo: widget.canMoveTo,
                  onSquareTap: widget.onSquareTap,
                  onMove: widget.onMove,
                  onPieceDragStarted: widget.onPieceDragStarted,
                  onPieceDragEnded: widget.onPieceDragEnded,
                  annotationModeEnabled: widget.isAnalysisMode,
                  annotationMarkedSquares: widget.annotationMarkedSquares,
                  annotationArrows: widget.annotationArrows,
                  onClearAnnotations: widget.onClearBoardAnnotations,
                  onToggleAnnotationSquare: widget.onToggleAnnotationSquare,
                  onToggleAnnotationArrow: widget.onToggleAnnotationArrow,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _statusHeaderHeight,
              child: MobileChessStatusHeader(
                height: _statusHeaderHeight,
                statusText: widget.statusText,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: _moveStripTop,
              height: _moveStripHeight,
              child: MobileChessMoveStrip(
                height: _moveStripHeight,
                pgnText: widget.pgnText,
                isAnalysisBranchActive: widget.isAnalysisBranchActive,
              ),
            ),
            if (!widget.isAnalysisMode)
              Positioned(
                left: 8,
                right: 8,
                top: resultStatsTop,
                height: _resultStatsHeight,
                child: MobileChessResultStatsPanel(counter: widget.trainingCounter),
              ),
            if (widget.isAnalysisMode)
              Positioned(
                left: 8,
                right: 8,
                top: analysisLinesBarTop,
                height: _analysisLinesBarHeight,
                child: MobileChessAnalysisLinesBar(
                  analysisLines: widget.analysisLines,
                ),
              ),
            if (gameInfoPanelHeight > 0)
              Positioned(
                left: 12,
                right: 12 +
                    _analysisButtonSize +
                    _gameInfoPanelHorizontalGap,
                top: gameInfoPanelTop,
                height: gameInfoPanelHeight,
                child: MobileChessGameInfoPanel(
                  skillLevel: widget.skillLevel,
                  uciElo: widget.uciElo,
                  cpLossElo: widget.cpLossElo,
                  cpLossUciSwitchFullMoveNumber:
                      widget.cpLossUciSwitchFullMoveNumber,
                  strengthMode: widget.strengthMode,
                  botOpeningMove: widget.botOpeningMove,
                  effectiveBotOpeningMove: widget.effectiveBotOpeningMove,
                  botPersonalitySource: widget.botPersonalitySource,
                  effectiveBotPersonalitySource:
                      widget.effectiveBotPersonalitySource,
                  botPersonality: widget.botPersonality,
                  effectiveBotPersonality: widget.effectiveBotPersonality,
                  fritz19Personality: widget.fritz19Personality,
                  effectiveFritz19Personality:
                      widget.effectiveFritz19Personality,
                  personaCandidateCount: widget.personaCandidateCount,
                  activeBotProfile: widget.activeBotProfile,
                ),
              ),
            Positioned(
              right: 12,
              top: analysisButtonTop,
              child: MobileChessAnalysisButton(
                size: _analysisButtonSize,
                isAnalysisMode: widget.isAnalysisMode,
                isEnabled: widget.canToggleAnalysisMode,
                onPressed: widget.onToggleAnalysisMode,
              ),
            ),
            if (canShowAnalysisUseIndicator)
              Positioned(
                right: 12,
                top: analysisUseIndicatorTop,
                width: _analysisButtonSize,
                height: _analysisUseIndicatorHeight,
                child: _AnalysisUseIndicatorBox(
                  analysisUsedDuringCurrentGame:
                      widget.analysisUsedDuringCurrentGame,
                ),
              ),
            if (canShowActionBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _actionBarHeight,
                child: MobileChessActionBar(
                  height: _actionBarHeight,
                  pgnText: widget.pgnText,
                  fenText: widget.fenText,
                  onTrainingRestart: widget.onTrainingRestart,
                  onMenuPressed: _toggleSideMenu,
                  isSideMenuOpen: _isSideMenuOpen,
                  isAnalysisMode: widget.isAnalysisMode,
                  canToggleAnalysisMode: widget.canToggleAnalysisMode,
                  canNavigateAnalysisBack: widget.canNavigateAnalysisBack,
                  canNavigateAnalysisForward: widget.canNavigateAnalysisForward,
                  onToggleAnalysisMode: widget.onToggleAnalysisMode,
                  onAnalysisBack: widget.onAnalysisBack,
                  onAnalysisForward: widget.onAnalysisForward,
                  onAnalysisBackToStart: widget.onAnalysisBackToStart,
                  onAnalysisForwardToEnd: widget.onAnalysisForwardToEnd,
                ),
              ),
            _buildClosedEdgeSwipeAreas(
              screenHeight: constraints.maxHeight,
              boardTop: boardTop,
              boardBottom: boardBottom,
            ),
            if (_isSideMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeSideMenu,
                  onHorizontalDragUpdate: _handleCloseSwipeUpdate,
                  onHorizontalDragEnd: _handleCloseSwipeEnd,
                  child: ColoredBox(color: Colors.black.withAlpha(145)),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              left: _isSideMenuOpen ? 0 : -sideMenuWidth,
              top: 0,
              bottom: 0,
              width: sideMenuWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _handleCloseSwipeUpdate,
                onHorizontalDragEnd: _handleCloseSwipeEnd,
                child: MobileChessSideMenu(
                  width: sideMenuWidth,
                  skillLevel: widget.skillLevel,
                  uciElo: widget.uciElo,
                  cpLossElo: widget.cpLossElo,
                  cpLossUciSwitchFullMoveNumber:
                      widget.cpLossUciSwitchFullMoveNumber,
                  strengthMode: widget.strengthMode,
                  botOpeningMove: widget.botOpeningMove,
                  effectiveBotOpeningMove: widget.effectiveBotOpeningMove,
                  selectedOpeningMoves: widget.selectedOpeningMoves,
                  botPersonalitySource: widget.botPersonalitySource,
                  effectiveBotPersonalitySource:
                      widget.effectiveBotPersonalitySource,
                  botPersonality: widget.botPersonality,
                  effectiveBotPersonality: widget.effectiveBotPersonality,
                  fritz19Personality: widget.fritz19Personality,
                  effectiveFritz19Personality:
                      widget.effectiveFritz19Personality,
                  selectedChessiversePersonalities:
                      widget.selectedChessiversePersonalities,
                  selectedFritz19Personalities:
                      widget.selectedFritz19Personalities,
                  personaCandidateCount: widget.personaCandidateCount,
                  draftSkillLevel: widget.draftSkillLevel,
                  draftUciElo: widget.draftUciElo,
                  draftCpLossElo: widget.draftCpLossElo,
                  draftCpLossUciSwitchFullMoveNumber:
                      widget.draftCpLossUciSwitchFullMoveNumber,
                  draftStrengthMode: widget.draftStrengthMode,
                  draftBotOpeningMove: widget.draftBotOpeningMove,
                  draftEffectiveBotOpeningMove:
                      widget.draftEffectiveBotOpeningMove,
                  draftSelectedOpeningMoves:
                      widget.draftSelectedOpeningMoves,
                  draftBotPersonalitySource: widget.draftBotPersonalitySource,
                  draftEffectiveBotPersonalitySource:
                      widget.draftEffectiveBotPersonalitySource,
                  draftBotPersonality: widget.draftBotPersonality,
                  draftEffectiveBotPersonality:
                      widget.draftEffectiveBotPersonality,
                  draftFritz19Personality: widget.draftFritz19Personality,
                  draftEffectiveFritz19Personality:
                      widget.draftEffectiveFritz19Personality,
                  draftSelectedChessiversePersonalities:
                      widget.draftSelectedChessiversePersonalities,
                  draftSelectedFritz19Personalities:
                      widget.draftSelectedFritz19Personalities,
                  draftPersonaCandidateCount: widget.draftPersonaCandidateCount,
                  activeBotProfile: widget.activeBotProfile,
                  draftBotProfile: widget.draftBotProfile,
                  normalSettingsLockedByBotProfile:
                      widget.normalSettingsLockedByBotProfile,
                  onBotProfileSelected: widget.onBotProfileSelected,
                  onBotProfileDisabled: widget.onBotProfileDisabled,
                  onNewGame: widget.onNewGame,
                  onRestart: widget.onRestart,
                  onSkillLevelChanged: widget.onSkillLevelChanged,
                  onUciEloChanged: widget.onUciEloChanged,
                  onCpLossEloChanged: widget.onCpLossEloChanged,
                  onCpLossUciSwitchFullMoveNumberChanged:
                      widget.onCpLossUciSwitchFullMoveNumberChanged,
                  onStrengthModeChanged: widget.onStrengthModeChanged,
                  onBotOpeningMoveChanged: widget.onBotOpeningMoveChanged,
                  onOpeningMoveSelectionToggled:
                      widget.onOpeningMoveSelectionToggled,
                  onOpeningMoveSelectionCleared:
                      widget.onOpeningMoveSelectionCleared,
                  onBotPersonalityChanged: widget.onBotPersonalityChanged,
                  onFritz19PersonalityChanged:
                      widget.onFritz19PersonalityChanged,
                  onChessiversePersonalitySelectionToggled:
                      widget.onChessiversePersonalitySelectionToggled,
                  onFritz19PersonalitySelectionToggled:
                      widget.onFritz19PersonalitySelectionToggled,
                  onPersonalitySelectionCleared:
                      widget.onPersonalitySelectionCleared,
                  onAllPersonalitiesRandomChanged:
                      widget.onAllPersonalitiesRandomChanged,
                  onPersonaCandidateCountChanged:
                      widget.onPersonaCandidateCountChanged,
                  onClose: _closeSideMenu,
                  isEnabled: widget.controlsEnabled && !widget.isAnalysisMode,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalysisUseIndicatorBox extends StatelessWidget {
  const _AnalysisUseIndicatorBox({
    required this.analysisUsedDuringCurrentGame,
  });

  final bool analysisUsedDuringCurrentGame;

  @override
  Widget build(BuildContext context) {
    final hasCleanGame = !analysisUsedDuringCurrentGame;

    return Semantics(
      label: hasCleanGame
          ? 'Analyse in dieser Partie nicht benutzt'
          : 'Analyse in dieser Partie benutzt',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(210),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasCleanGame
                ? const Color(0xFF55C878).withAlpha(150)
                : const Color(0xFFFF5A5A).withAlpha(150),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            hasCleanGame ? '✅' : '❌',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeSwipeDetector extends StatelessWidget {
  const _EdgeSwipeDetector({
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
  });

  final GestureDragUpdateCallback onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: const SizedBox.expand(),
    );
  }
}



