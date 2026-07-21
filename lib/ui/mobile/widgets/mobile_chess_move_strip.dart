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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToLatestMove();
  }

  @override
  void didUpdateWidget(covariant MobileChessMoveStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entries.length < widget.entries.length) {
      _scrollToLatestMove();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatestMove() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
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
            : ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tokens.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final token = tokens[index];

                  return Center(
                    child: _MoveStripChip(
                      token: token,
                      isAnalysisBranchActive: widget.isAnalysisBranchActive,
                      onTap: token.ply == null
                          ? null
                          : () {
                              widget.onMoveSelected(token.ply!);
                            },
                    ),
                  );
                },
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
          style: const TextStyle(
            color: Color(0xFF9A9A9A),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
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
            style: TextStyle(
              color: token.isCurrentMove
                  ? Colors.white
                  : Colors.white.withAlpha(220),
              fontSize: 19,
              fontWeight: FontWeight.w800,
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
