import 'package:flutter/material.dart';

class MobileChessMoveStrip extends StatefulWidget {
  const MobileChessMoveStrip({
    super.key,
    required this.pgnText,
    this.isAnalysisBranchActive = false,
    this.height = 54,
  });

  final String pgnText;
  final bool isAnalysisBranchActive;
  final double height;

  @override
  State<MobileChessMoveStrip> createState() => _MobileChessMoveStripState();
}

class _MobileChessMoveStripState extends State<MobileChessMoveStrip> {
  final ScrollController _scrollController = ScrollController();

  List<_MoveStripToken> _tokens = const [];

  @override
  void initState() {
    super.initState();
    _tokens = _parsePgn(widget.pgnText);
    _scrollToLatestMove();
  }

  @override
  void didUpdateWidget(covariant MobileChessMoveStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pgnText == widget.pgnText) {
      return;
    }

    _tokens = _parsePgn(widget.pgnText);
    _scrollToLatestMove();
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

  List<_MoveStripToken> _parsePgn(String pgnText) {
    final trimmed = pgnText.trim();

    if (trimmed.isEmpty || trimmed == '-') {
      return const [];
    }

    final withoutTags = trimmed
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (withoutTags.isEmpty || withoutTags == '-') {
      return const [];
    }

    final parts = withoutTags
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    var currentMoveIndex = -1;

    for (var index = parts.length - 1; index >= 0; index--) {
      if (!_isMoveNumber(parts[index]) && !_isGameResult(parts[index])) {
        currentMoveIndex = index;
        break;
      }
    }

    return [
      for (var index = 0; index < parts.length; index++)
        _MoveStripToken(
          text: parts[index],
          isMoveNumber: _isMoveNumber(parts[index]),
          isCurrentMove: index == currentMoveIndex,
        ),
    ];
  }

  bool _isMoveNumber(String token) {
    return RegExp(r'^\d+\.(\.\.)?$').hasMatch(token);
  }

  bool _isGameResult(String token) {
    return token == '1-0' || token == '0-1' || token == '1/2-1/2' || token == '*';
  }

  @override
  Widget build(BuildContext context) {
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
        child: _tokens.isEmpty
            ? const _EmptyMoveStrip()
            : ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _tokens.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final token = _tokens[index];

                  return Center(
                    child: _MoveStripChip(
                      token: token,
                      isAnalysisBranchActive: widget.isAnalysisBranchActive,
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
  });

  final _MoveStripToken token;
  final bool isAnalysisBranchActive;

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: token.isCurrentMove ? currentColor.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: token.isCurrentMove ? currentColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        token.text,
        style: TextStyle(
          color: token.isCurrentMove ? Colors.white : Colors.white.withAlpha(220),
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MoveStripToken {
  const _MoveStripToken({
    required this.text,
    required this.isMoveNumber,
    required this.isCurrentMove,
  });

  final String text;
  final bool isMoveNumber;
  final bool isCurrentMove;
}
