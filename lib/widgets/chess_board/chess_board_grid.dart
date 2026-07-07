import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/board_annotation.dart';
import '../../models/board_highlights.dart';
import '../../utils/chess_square_utils.dart';
import 'chess_board_square.dart';

class ChessBoardGrid extends StatefulWidget {
  const ChessBoardGrid({
    required this.playerIsWhite,
    required this.highlights,
    required this.pieceAt,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.legalTargetsFromSquare,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
    this.isAnalysisMode = false,
    this.annotationModeEnabled = false,
    this.annotationMarkedSquares = const <String>{},
    this.annotationArrows = const <BoardArrowAnnotation>{},
    this.onClearAnnotations,
    this.onToggleAnnotationSquare,
    this.onToggleAnnotationArrow,
    super.key,
  });

  final bool playerIsWhite;
  final bool isAnalysisMode;
  final BoardHighlights highlights;
  final chess.Piece? Function(String square) pieceAt;
  final bool Function(String square) canHumanMovePiece;
  final bool Function({required String from, required String to}) canMoveTo;
  final List<String> Function(String fromSquare) legalTargetsFromSquare;
  final Future<void> Function(String square) onSquareTap;

  final Future<bool> Function({
    required String from,
    required String to,
    String? promotion,
  })
  onMove;

  final ValueChanged<String> onPieceDragStarted;
  final VoidCallback onPieceDragEnded;

  final bool annotationModeEnabled;
  final Set<String> annotationMarkedSquares;
  final Set<BoardArrowAnnotation> annotationArrows;
  final VoidCallback? onClearAnnotations;
  final ValueChanged<String>? onToggleAnnotationSquare;
  final ValueChanged<BoardArrowAnnotation>? onToggleAnnotationArrow;

  @override
  State<ChessBoardGrid> createState() => _ChessBoardGridState();
}

class _ChessBoardGridState extends State<ChessBoardGrid> {
  static const double _windowsBoardCornerRadius = 10;
  static const ColorFilter _analysisBoardTextureColorFilter =
      ColorFilter.matrix(<double>[
        0.78, 0.16, 0.06, 0, 0,
        0.12, 0.86, 0.06, 0, 0,
        0.12, 0.16, 0.74, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  String? _annotationDragStartSquare;
  String? _annotationDragCurrentSquare;

  BorderRadius get _boardBorderRadius {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return BorderRadius.zero;
    }

    return BorderRadius.circular(_windowsBoardCornerRadius);
  }

  @override
  void didUpdateWidget(covariant ChessBoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.annotationModeEnabled && oldWidget.annotationModeEnabled) {
      _resetAnnotationDragPreview();
    }
  }

  void _handlePointerDown(PointerDownEvent event, double boardSize) {
    if (_isPrimaryMouseButton(event.buttons)) {
      widget.onClearAnnotations?.call();
      return;
    }

    if (!widget.annotationModeEnabled || !_isSecondaryMouseButton(event.buttons)) {
      return;
    }

    final square = _squareFromLocalPosition(
      event.localPosition,
      boardSize: boardSize,
      playerIsWhite: widget.playerIsWhite,
    );

    if (square == null) {
      return;
    }

    setState(() {
      _annotationDragStartSquare = square;
      _annotationDragCurrentSquare = square;
    });
  }

  void _handlePointerMove(PointerMoveEvent event, double boardSize) {
    if (!widget.annotationModeEnabled ||
        _annotationDragStartSquare == null ||
        !_isSecondaryMouseButton(event.buttons)) {
      return;
    }

    final square = _squareFromLocalPosition(
      event.localPosition,
      boardSize: boardSize,
      playerIsWhite: widget.playerIsWhite,
    );

    if (square == null || square == _annotationDragCurrentSquare) {
      return;
    }

    setState(() {
      _annotationDragCurrentSquare = square;
    });
  }

  void _handlePointerUp(PointerUpEvent event, double boardSize) {
    if (!widget.annotationModeEnabled || _annotationDragStartSquare == null) {
      _resetAnnotationDragPreview();
      return;
    }

    final from = _annotationDragStartSquare!;
    final to = _squareFromLocalPosition(
          event.localPosition,
          boardSize: boardSize,
          playerIsWhite: widget.playerIsWhite,
        ) ??
        _annotationDragCurrentSquare ??
        from;

    _resetAnnotationDragPreview();

    if (from == to) {
      widget.onToggleAnnotationSquare?.call(from);
      return;
    }

    widget.onToggleAnnotationArrow?.call(
      BoardArrowAnnotation(from: from, to: to),
    );
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _resetAnnotationDragPreview();
  }

  void _resetAnnotationDragPreview() {
    if (_annotationDragStartSquare == null &&
        _annotationDragCurrentSquare == null) {
      return;
    }

    setState(() {
      _annotationDragStartSquare = null;
      _annotationDragCurrentSquare = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            final previewArrow = _previewArrow;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _handlePointerDown(event, boardSize),
                onPointerMove: (event) => _handlePointerMove(event, boardSize),
                onPointerUp: (event) => _handlePointerUp(event, boardSize),
                onPointerCancel: _handlePointerCancel,
                child: ClipRRect(
                  borderRadius: _boardBorderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildBoardTextureLayer()),
                      GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 64,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                          ),
                      itemBuilder: (context, index) {
                        final square = squareNameFromIndex(
                          index: index,
                          playerIsWhite: widget.playerIsWhite,
                        );

                        return ChessBoardSquare(
                          square: square,
                          piece: widget.pieceAt(square),
                          isLightSquare: isLightSquareFromIndex(index),
                          isAnalysisMode: widget.isAnalysisMode,
                          highlights: widget.highlights,
                          canHumanMovePiece: widget.canHumanMovePiece(square),
                          canMoveTo: widget.canMoveTo,
                          legalTargetsFromSquare: widget.legalTargetsFromSquare,
                          onSquareTap: widget.onSquareTap,
                          onMove: widget.onMove,
                          onPieceDragStarted: widget.onPieceDragStarted,
                          onPieceDragEnded: widget.onPieceDragEnded,
                        );
                      },
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _BoardAnnotationPainter(
                            playerIsWhite: widget.playerIsWhite,
                            markedSquares: widget.annotationMarkedSquares,
                            arrows: widget.annotationArrows,
                            previewArrow: previewArrow,
                          ),
                        ),
                      ),
                    ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BoardCoordinatePainter(
                              playerIsWhite: widget.playerIsWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoardTextureLayer() {
    final image = Image.asset(
      'assets/board/maple.jpg',
      fit: BoxFit.cover,
    );

    if (!widget.isAnalysisMode) {
      return image;
    }

    // Nur die Brettfläche/Textur wird entsättigt. Die Figuren liegen später
    // darüber und bleiben deshalb farblich unverändert.
    return ColorFiltered(
      colorFilter: _analysisBoardTextureColorFilter,
      child: image,
    );
  }

  BoardArrowAnnotation? get _previewArrow {
    final from = _annotationDragStartSquare;
    final to = _annotationDragCurrentSquare;

    if (from == null || to == null || from == to) {
      return null;
    }

    return BoardArrowAnnotation(from: from, to: to);
  }
}

class _BoardAnnotationPainter extends CustomPainter {
  const _BoardAnnotationPainter({
    required this.playerIsWhite,
    required this.markedSquares,
    required this.arrows,
    this.previewArrow,
  });

  static const Color _highlighterGreen = Color(0xFF006B2E);

  final bool playerIsWhite;
  final Set<String> markedSquares;
  final Set<BoardArrowAnnotation> arrows;
  final BoardArrowAnnotation? previewArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = math.min(size.width, size.height) / 8.0;
    final markerStrokeWidth = squareSize * 0.11;
    final arrowStrokeWidth = squareSize * 0.18;

    final markerPaint = Paint()
      ..color = _highlighterGreen.withAlpha(118)
      ..blendMode = BlendMode.src
      ..strokeWidth = markerStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPaint = Paint()
      ..color = _highlighterGreen.withAlpha(118)
      ..blendMode = BlendMode.src
      ..strokeWidth = arrowStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Jedes einzelne Textmarker-Element wird intern auf eine eigene Ebene
    // gezeichnet. Innerhalb eines Pfeils/Kreises verhindert BlendMode.src,
    // dass sich Linie und Pfeilkopf gegenseitig abdunkeln. Verschiedene
    // Pfeile/Kreise dürfen sich dagegen wie echte Textmarker überlagern.
    for (final square in markedSquares) {
      _paintSingleHighlighterElement(canvas, size, () {
        _drawSquareMarker(canvas, square, squareSize, markerPaint);
      });
    }

    for (final arrow in arrows) {
      _paintSingleHighlighterElement(canvas, size, () {
        _drawArrow(canvas, arrow, squareSize, arrowPaint);
      });
    }

    final preview = previewArrow;
    if (preview != null) {
      final previewPaint = Paint()
        ..color = _highlighterGreen.withAlpha(82)
        ..blendMode = BlendMode.src
        ..strokeWidth = arrowStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      _paintSingleHighlighterElement(canvas, size, () {
        _drawArrow(canvas, preview, squareSize, previewPaint);
      });
    }
  }

  void _paintSingleHighlighterElement(
    Canvas canvas,
    Size size,
    VoidCallback paintElement,
  ) {
    canvas.saveLayer(Offset.zero & size, Paint());
    paintElement();
    canvas.restore();
  }

  void _drawSquareMarker(
    Canvas canvas,
    String square,
    double squareSize,
    Paint paint,
  ) {
    final center = _centerForSquare(square, squareSize);

    if (center == null) {
      return;
    }

    final radius = (squareSize * 0.5) - (paint.strokeWidth * 0.5) - 1.0;

    if (radius <= 0) {
      return;
    }

    canvas.drawCircle(center, radius, paint);
  }

  void _drawArrow(
    Canvas canvas,
    BoardArrowAnnotation arrow,
    double squareSize,
    Paint paint,
  ) {
    final from = _centerForSquare(arrow.from, squareSize);
    final to = _centerForSquare(arrow.to, squareSize);

    if (from == null || to == null) {
      return;
    }

    final points = arrow.isKnightMove
        ? _knightArrowPoints(from: from, to: to, arrow: arrow)
        : <Offset>[from, to];

    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, points[points.length - 2], points.last, paint);
  }

  List<Offset> _knightArrowPoints({
    required Offset from,
    required Offset to,
    required BoardArrowAnnotation arrow,
  }) {
    final fromFile = arrow.from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toFile = arrow.to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRank = int.tryParse(arrow.from.substring(1, 2)) ?? 1;
    final toRank = int.tryParse(arrow.to.substring(1, 2)) ?? 1;

    final fileDelta = (toFile - fromFile).abs();
    final rankDelta = (toRank - fromRank).abs();

    if (rankDelta > fileDelta) {
      return <Offset>[from, Offset(from.dx, to.dy), to];
    }

    return <Offset>[from, Offset(to.dx, from.dy), to];
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = to - from;

    if (direction.distance == 0) {
      return;
    }

    final angle = math.atan2(direction.dy, direction.dx);
    final headLength = paint.strokeWidth * 2.0;
    final headAngle = math.pi / 6;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - headLength * math.cos(angle - headAngle),
        to.dy - headLength * math.sin(angle - headAngle),
      )
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - headLength * math.cos(angle + headAngle),
        to.dy - headLength * math.sin(angle + headAngle),
      );

    canvas.drawPath(path, paint);
  }

  Offset? _centerForSquare(String square, double squareSize) {
    if (square.length != 2) {
      return null;
    }

    final fileIndex = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(square.substring(1, 2));

    if (fileIndex < 0 || fileIndex > 7 || rank == null || rank < 1 || rank > 8) {
      return null;
    }

    final rankIndex = rank - 1;
    final col = playerIsWhite ? fileIndex : 7 - fileIndex;
    final row = playerIsWhite ? 7 - rankIndex : rankIndex;

    return Offset((col + 0.5) * squareSize, (row + 0.5) * squareSize);
  }

  @override
  bool shouldRepaint(covariant _BoardAnnotationPainter oldDelegate) {
    return oldDelegate.playerIsWhite != playerIsWhite ||
        oldDelegate.markedSquares != markedSquares ||
        oldDelegate.arrows != arrows ||
        oldDelegate.previewArrow != previewArrow;
  }
}

class _BoardCoordinatePainter extends CustomPainter {
  const _BoardCoordinatePainter({required this.playerIsWhite});

  final bool playerIsWhite;

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = math.min(size.width, size.height);
    final squareSize = boardSize / 8.0;
    final fontSize = (squareSize * 0.135).clamp(8.0, 12.0).toDouble();
    final inset = (squareSize * 0.055).clamp(3.0, 5.0).toDouble();

    for (var row = 0; row < 8; row++) {
      final rank = playerIsWhite ? 8 - row : row + 1;
      final squareIsLight = _isDisplayedSquareLight(row: row, col: 7);
      final color = _coordinateColorForSquare(squareIsLight);
      final painter = _textPainter(
        text: '$rank',
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w900,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          boardSize - painter.width - inset,
          row * squareSize + inset * 0.45,
        ),
      );
    }

    for (var col = 0; col < 8; col++) {
      final fileIndex = playerIsWhite ? col : 7 - col;
      final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
      final squareIsLight = _isDisplayedSquareLight(row: 7, col: col);
      final color = _coordinateColorForSquare(squareIsLight);
      final painter = _textPainter(
        text: file,
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w900,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          col * squareSize + inset,
          boardSize - painter.height - inset * 0.35,
        ),
      );
    }
  }

  bool _isDisplayedSquareLight({required int row, required int col}) {
    return (row + col).isEven;
  }

  Color _coordinateColorForSquare(bool squareIsLight) {
    if (squareIsLight) {
      return Colors.black.withAlpha(150);
    }

    return Colors.white.withAlpha(215);
  }

  TextPainter _textPainter({
    required String text,
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1,
          shadows: const [
            Shadow(
              color: Colors.black38,
              blurRadius: 1.5,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardCoordinatePainter oldDelegate) {
    return oldDelegate.playerIsWhite != playerIsWhite;
  }
}

bool _isPrimaryMouseButton(int buttons) {
  return (buttons & kPrimaryMouseButton) != 0;
}

bool _isSecondaryMouseButton(int buttons) {
  return (buttons & kSecondaryMouseButton) != 0;
}

String? _squareFromLocalPosition(
  Offset position, {
  required double boardSize,
  required bool playerIsWhite,
}) {
  if (boardSize <= 0 ||
      position.dx < 0 ||
      position.dy < 0 ||
      position.dx >= boardSize ||
      position.dy >= boardSize) {
    return null;
  }

  final squareSize = boardSize / 8.0;
  final col = (position.dx / squareSize).floor().clamp(0, 7).toInt();
  final row = (position.dy / squareSize).floor().clamp(0, 7).toInt();

  final fileIndex = playerIsWhite ? col : 7 - col;
  final rank = playerIsWhite ? 8 - row : row + 1;
  final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);

  return '$file$rank';
}


