import 'package:flutter/material.dart';

import '../../../controllers/chess_board_controller.dart';

class MobileChessMoveStrip extends StatefulWidget {
  const MobileChessMoveStrip({
    super.key,
    required this.entries,
    required this.selectedPly,
    required this.onMoveSelected,
    this.isAnalysisBranchActive = false,
    this.height = 54,
  });

  final List<ChessMoveListEntry> entries;
  final int selectedPly;
  final Future<void> Function(int ply) onMoveSelected;
  final bool isAnalysisBranchActive;
  final double height;

  @override
  State<MobileChessMoveStrip> createState() => _MobileChessMoveStripState();
}

class _MobileChessMoveStripState extends State<MobileChessMoveStrip> {
  static const double _horizontalPadding = 12;
  static const double _tokenSpacing = 6;
  static const double _edgeInset = 6;
  static const TextStyle _moveNumberStyle = TextStyle(
    color: Color(0xFF9A9A9A),
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle _moveTextStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _moveKeys = <int, GlobalKey>{};
  int _scrollRequestSerial = 0;
  DateTime? _lastSelectionChangeAt;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToSelectedMove(animated: false);
  }

  @override
  void didUpdateWidget(covariant MobileChessMoveStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPly != widget.selectedPly ||
        oldWidget.entries.length != widget.entries.length) {
      _scheduleScrollToSelectedMove();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToSelectedMove({bool animated = true}) {
    final requestSerial = ++_scrollRequestSerial;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          requestSerial != _scrollRequestSerial ||
          !_scrollController.hasClients) {
        return;
      }

      _scrollToSelectedMove(animated: animated);
    });
  }

  void _scrollToSelectedMove({required bool animated}) {
    final position = _scrollController.position;

    if (widget.selectedPly <= 0) {
      _moveScrollPositionTo(position.minScrollExtent, animated: animated);
      return;
    }

    final viewportContext = _viewportKey.currentContext;
    final selectedContext = _moveKeys[widget.selectedPly]?.currentContext;
    final viewportBox = viewportContext?.findRenderObject();
    final selectedBox = selectedContext?.findRenderObject();

    if (viewportBox is! RenderBox || selectedBox is! RenderBox) {
      return;
    }

    final viewportOrigin = viewportBox.localToGlobal(Offset.zero);
    final selectedOrigin = selectedBox.localToGlobal(Offset.zero);
    final viewportLeft = viewportOrigin.dx + _edgeInset;
    final viewportRight =
        viewportOrigin.dx + viewportBox.size.width - _edgeInset;
    final selectedLeft = selectedOrigin.dx;
    final selectedRight = selectedOrigin.dx + selectedBox.size.width;

    double? targetOffset;
    if (selectedLeft < viewportLeft) {
      targetOffset = position.pixels - (viewportLeft - selectedLeft);
    } else if (selectedRight > viewportRight) {
      targetOffset = position.pixels + (selectedRight - viewportRight);
    }

    final now = DateTime.now();
    final isRapidNavigation = _lastSelectionChangeAt != null &&
        now.difference(_lastSelectionChangeAt!) <
            const Duration(milliseconds: 140);
    _lastSelectionChangeAt = now;

    if (targetOffset == null) {
      return;
    }

    final clampedTarget = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _moveScrollPositionTo(
      clampedTarget.toDouble(),
      animated: animated && !isRapidNavigation,
    );
  }

  void _moveScrollPositionTo(double offset, {required bool animated}) {
    if ((_scrollController.offset - offset).abs() < 1) {
      return;
    }

    if (!animated) {
      _scrollController.jumpTo(offset);
      return;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
    );
  }

  List<_MoveStripToken> _buildTokens() {
    final tokens = <_MoveStripToken>[];
    ChessMoveListEntry? previousEntry;

    for (final entry in widget.entries) {
      final startsNewMoveNumber = previousEntry == null ||
          previousEntry.fullMoveNumber != entry.fullMoveNumber;

      if (startsNewMoveNumber) {
        tokens.add(
          _MoveStripToken(
            text: entry.isWhiteMove
                ? '${entry.fullMoveNumber}.'
                : '${entry.fullMoveNumber}...',
            isMoveNumber: true,
          ),
        );
      }

      tokens.add(
        _MoveStripToken(
          text: entry.san,
          ply: entry.ply,
          isCurrentMove: widget.selectedPly == entry.ply,
        ),
      );

      previousEntry = entry;
    }

    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _buildTokens();

    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(150),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(14), width: 1),
            bottom: BorderSide(color: Colors.white.withAlpha(22), width: 1),
          ),
        ),
        child: tokens.isEmpty
            ? const _EmptyMoveStrip()
            : SingleChildScrollView(
                key: _viewportKey,
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < tokens.length; index++) ...[
                      if (index > 0)
                        const SizedBox(width: _tokenSpacing),
                      Padding(
                        key: tokens[index].ply == null
                            ? null
                            : _moveKeys.putIfAbsent(
                                tokens[index].ply!,
                                () => GlobalKey(),
                              ),
                        padding: EdgeInsets.zero,
                        child: _MoveStripChip(
                          token: tokens[index],
                          isAnalysisBranchActive:
                              widget.isAnalysisBranchActive,
                          onTap: tokens[index].ply == null
                              ? null
                              : () {
                                  widget.onMoveSelected(tokens[index].ply!);
                                },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyMoveStrip extends StatelessWidget {
  const _EmptyMoveStrip();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Noch keine Züge',
          style: TextStyle(
            color: Color(0xFF8E8E8E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MoveStripChip extends StatelessWidget {
  const _MoveStripChip({
    required this.token,
    required this.isAnalysisBranchActive,
    required this.onTap,
  });

  final _MoveStripToken token;
  final bool isAnalysisBranchActive;
  final VoidCallback? onTap;

  static const Color _accentColor = Color(0xFF5C9DFF);
  static const Color _branchColor = Color(0xFF9A9A9A);

  @override
  Widget build(BuildContext context) {
    if (token.isMoveNumber) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          token.text,
          style: _MobileChessMoveStripState._moveNumberStyle,
        ),
      );
    }

    final currentColor = isAnalysisBranchActive ? _branchColor : _accentColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: token.isCurrentMove
                ? currentColor.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: token.isCurrentMove ? currentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            token.text,
            style: _MobileChessMoveStripState._moveTextStyle.copyWith(
              color: token.isCurrentMove
                  ? Colors.white
                  : Colors.white.withAlpha(220),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveStripToken {
  const _MoveStripToken({
    required this.text,
    this.ply,
    this.isMoveNumber = false,
    this.isCurrentMove = false,
  });

  final String text;
  final int? ply;
  final bool isMoveNumber;
  final bool isCurrentMove;
}
