import 'package:flutter/material.dart';

import '../controllers/chess_board_controller.dart';

class ChessMoveListPanel extends StatelessWidget {
  const ChessMoveListPanel({
    super.key,
    required this.entries,
    required this.selectedPly,
    required this.isReviewMode,
    required this.isAnalysisMode,
    required this.onMoveSelected,
  });

  final List<ChessMoveListEntry> entries;
  final int selectedPly;
  final bool isReviewMode;
  final bool isAnalysisMode;
  final Future<void> Function(int ply) onMoveSelected;

  static const Color _panelBackground = Color(0xFF101722);
  static const Color _panelBorder = Color(0xFF2B3A4E);
  static const Color _accent = Color(0xFFAEDBFF);
  static const Color _selectedBackground = Color(0xFF285B8E);

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(entries);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panelBackground.withAlpha(235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBadge(
              isReviewMode: isReviewMode,
              isAnalysisMode: isAnalysisMode,
              selectedPly: selectedPly,
              totalPly: entries.length,
            ),
            const SizedBox(height: 10),
            _StartPositionTile(
              isSelected: selectedPly == 0,
              onTap: () => onMoveSelected(0),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'Noch keine Züge',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];

                        return _MoveListRow(
                          row: row,
                          selectedPly: selectedPly,
                          onMoveSelected: onMoveSelected,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MoveRowData> _buildRows(List<ChessMoveListEntry> entries) {
    final rows = <_MoveRowData>[];

    for (final entry in entries) {
      _MoveRowData row;

      if (rows.isNotEmpty && rows.last.fullMoveNumber == entry.fullMoveNumber) {
        row = rows.last;
      } else {
        row = _MoveRowData(fullMoveNumber: entry.fullMoveNumber);
        rows.add(row);
      }

      if (entry.isWhiteMove) {
        row.whiteMove = entry;
      } else {
        row.blackMove = entry;
      }
    }

    return rows;
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.isReviewMode,
    required this.isAnalysisMode,
    required this.selectedPly,
    required this.totalPly,
  });

  final bool isReviewMode;
  final bool isAnalysisMode;
  final int selectedPly;
  final int totalPly;

  @override
  Widget build(BuildContext context) {
    final modeText = isAnalysisMode
        ? 'Analyse'
        : isReviewMode
            ? 'Rückblick'
            : 'Live';

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Zugliste',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ChessMoveListPanel._accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Text(
              '$modeText $selectedPly/$totalPly',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartPositionTile extends StatelessWidget {
  const _StartPositionTile({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MoveCell(
      text: 'Startstellung',
      isSelected: isSelected,
      onTap: onTap,
      textAlign: TextAlign.center,
    );
  }
}

class _MoveListRow extends StatelessWidget {
  const _MoveListRow({
    required this.row,
    required this.selectedPly,
    required this.onMoveSelected,
  });

  final _MoveRowData row;
  final int selectedPly;
  final Future<void> Function(int ply) onMoveSelected;

  @override
  Widget build(BuildContext context) {
    final whiteMove = row.whiteMove;
    final blackMove = row.blackMove;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${row.fullMoveNumber}.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withAlpha(145),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: whiteMove == null
                ? const SizedBox(height: 32)
                : _MoveCell(
                    text: whiteMove.san,
                    isSelected: selectedPly == whiteMove.ply,
                    onTap: () {
                      onMoveSelected(whiteMove.ply);
                    },
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: blackMove == null
                ? const SizedBox(height: 32)
                : _MoveCell(
                    text: blackMove.san,
                    isSelected: selectedPly == blackMove.ply,
                    onTap: () {
                      onMoveSelected(blackMove.ply);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoveCell extends StatelessWidget {
  const _MoveCell({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? ChessMoveListPanel._selectedBackground
          : Colors.white.withAlpha(14),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          alignment: textAlign == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withAlpha(220),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveRowData {
  _MoveRowData({required this.fullMoveNumber});

  final int fullMoveNumber;
  ChessMoveListEntry? whiteMove;
  ChessMoveListEntry? blackMove;
}
