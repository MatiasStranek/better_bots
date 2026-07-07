import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../models/board_highlights.dart';
import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/player_side.dart';
import '../widgets/chess_board/mobile_chess_board_view.dart';
import '../widgets/mobile_chess_action_bar.dart';
import '../widgets/mobile_chess_analysis_button.dart';
import '../widgets/mobile_chess_game_info_panel.dart';
import '../widgets/mobile_chess_move_strip.dart';
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
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.personaCandidateCount,
    required this.isAnalysisMode,
    required this.canToggleAnalysisMode,
    required this.onToggleAnalysisMode,
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
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final int personaCandidateCount;

  final bool isAnalysisMode;
  final bool canToggleAnalysisMode;
  final VoidCallback onToggleAnalysisMode;

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

  final bool controlsEnabled;

  @override
  State<MobileChessBoardLayout> createState() => _MobileChessBoardLayoutState();
}

class _MobileChessBoardLayoutState extends State<MobileChessBoardLayout> {
  static const double _screenPadding = 16;
  static const double _statusHeaderHeight = 48;
  static const double _moveStripTop = 48;
  static const double _moveStripHeight = 54;
  static const double _actionBarHeight = 64;
  static const double _analysisButtonSize = 52;
  static const double _analysisButtonGap = 8;
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
        final gameInfoPanelHeight = _gameInfoPanelHeight(
          top: analysisButtonTop,
          screenHeight: constraints.maxHeight,
        );

        return Stack(
          children: [
            Center(
              child: SizedBox.square(
                dimension: boardSize,
                child: MobileChessBoardView(
                  playerIsWhite: widget.playerIsWhite,
                  pieceAt: widget.pieceAt,
                  highlights: widget.highlights,
                  canHumanMovePiece: widget.canHumanMovePiece,
                  canMoveTo: widget.canMoveTo,
                  onSquareTap: widget.onSquareTap,
                  onMove: widget.onMove,
                  onPieceDragStarted: widget.onPieceDragStarted,
                  onPieceDragEnded: widget.onPieceDragEnded,
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
              ),
            ),
            if (gameInfoPanelHeight > 0)
              Positioned(
                left: 12,
                right: 12 +
                    _analysisButtonSize +
                    _gameInfoPanelHorizontalGap,
                top: analysisButtonTop,
                height: gameInfoPanelHeight,
                child: MobileChessGameInfoPanel(
                  skillLevel: widget.skillLevel,
                  uciElo: widget.uciElo,
                  cpLossElo: widget.cpLossElo,
                  cpLossUciSwitchFullMoveNumber:
                      widget.cpLossUciSwitchFullMoveNumber,
                  strengthMode: widget.strengthMode,
                  botOpeningMove: widget.botOpeningMove,
                  botPersonality: widget.botPersonality,
                  effectiveBotPersonality: widget.effectiveBotPersonality,
                  personaCandidateCount: widget.personaCandidateCount,
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
                  onRestart: widget.onRestart,
                  onMenuPressed: _toggleSideMenu,
                  isSideMenuOpen: _isSideMenuOpen,
                  canToggleAnalysisMode: widget.canToggleAnalysisMode,
                  onToggleAnalysisMode: widget.onToggleAnalysisMode,
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
                  botPersonality: widget.botPersonality,
                  effectiveBotPersonality: widget.effectiveBotPersonality,
                  personaCandidateCount: widget.personaCandidateCount,
                  onNewGame: widget.onNewGame,
                  onRestart: widget.onRestart,
                  onSkillLevelChanged: widget.onSkillLevelChanged,
                  onUciEloChanged: widget.onUciEloChanged,
                  onCpLossEloChanged: widget.onCpLossEloChanged,
                  onCpLossUciSwitchFullMoveNumberChanged:
                      widget.onCpLossUciSwitchFullMoveNumberChanged,
                  onStrengthModeChanged: widget.onStrengthModeChanged,
                  onBotOpeningMoveChanged: widget.onBotOpeningMoveChanged,
                  onBotPersonalityChanged: widget.onBotPersonalityChanged,
                  onPersonaCandidateCountChanged:
                      widget.onPersonaCandidateCountChanged,
                  onClose: _closeSideMenu,
                  isEnabled: widget.controlsEnabled,
                ),
              ),
            ),
          ],
        );
      },
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
