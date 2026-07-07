import 'dart:async';
import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../../../models/board_annotation.dart';
import '../../../../models/board_highlights.dart';
import 'mobile_chess_board_square.dart';

class MobileChessBoardView extends StatefulWidget {
  const MobileChessBoardView({
    super.key,
    required this.playerIsWhite,
    this.isAnalysisMode = false,
    required this.pieceAt,
    required this.highlights,
    required this.canHumanMovePiece,
    required this.canMoveTo,
    required this.onSquareTap,
    required this.onMove,
    required this.onPieceDragStarted,
    required this.onPieceDragEnded,
    this.annotationModeEnabled = false,
    this.annotationMarkedSquares = const <String>{},
    this.annotationArrows = const <BoardArrowAnnotation>{},
    this.onClearAnnotations,
    this.onToggleAnnotationSquare,
    this.onToggleAnnotationArrow,
  });

  final bool playerIsWhite;
  final bool isAnalysisMode;
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

  final bool annotationModeEnabled;
  final Set<String> annotationMarkedSquares;
  final Set<BoardArrowAnnotation> annotationArrows;
  final VoidCallback? onClearAnnotations;
  final ValueChanged<String>? onToggleAnnotationSquare;
  final ValueChanged<BoardArrowAnnotation>? onToggleAnnotationArrow;

  @override
  State<MobileChessBoardView> createState() => _MobileChessBoardViewState();
}

class _MobileChessBoardViewState extends State<MobileChessBoardView> {
  static const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const double _dragHoverCircleRadiusInSquares = 1.0;
  static const double _annotationDragStartThreshold = 20.0;
  static const Duration _annotationLongPressDuration =
      Duration(milliseconds: 300);
  static const ColorFilter _analysisBoardTextureColorFilter =
      ColorFilter.matrix(<double>[
        0.78, 0.16, 0.06, 0, 0,
        0.12, 0.86, 0.06, 0, 0,
        0.12, 0.16, 0.74, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  String? _hoveredDragTargetSquare;
  int? _annotationPointer;
  Offset? _annotationPointerStartPosition;
  String? _annotationDragStartSquare;
  String? _annotationDragCurrentSquare;
  Timer? _annotationLongPressTimer;
  bool _annotationPointerMoved = false;
  bool _annotationLongPressTriggered = false;
  bool _suppressNextSquareTap = false;

  @override
  void didUpdateWidget(covariant MobileChessBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.annotationModeEnabled && oldWidget.annotationModeEnabled) {
      _resetAnnotationGestureState();
    }
  }

  @override
  void dispose() {
    _annotationLongPressTimer?.cancel();
    super.dispose();
  }

  String _squareForIndex(int index) {
    final row = index ~/ 8;
    final column = index % 8;

    final fileIndex = widget.playerIsWhite ? column : 7 - column;
    final rank = widget.playerIsWhite ? 8 - row : row + 1;

    return '${_files[fileIndex]}$rank';
  }

  bool _isLightSquare(String square) {
    final file = square.substring(0, 1);
    final rank = int.parse(square.substring(1, 2));
    final fileIndex = _files.indexOf(file);

    return (fileIndex + rank).isEven;
  }

  String? _pieceCodeForPiece(chess.Piece? piece) {
    if (piece == null) {
      return null;
    }

    final colorPrefix = piece.color == chess.Color.WHITE ? 'w' : 'b';
    final pieceType = _pieceLetter(piece);

    return '$colorPrefix$pieceType';
  }

  String _pieceLetter(chess.Piece piece) {
    final typeText = piece.type.toString().toLowerCase();

    if (typeText == 'p' ||
        typeText.endsWith('.p') ||
        typeText.contains('pawn')) {
      return 'P';
    }

    if (typeText == 'n' ||
        typeText.endsWith('.n') ||
        typeText.contains('knight')) {
      return 'N';
    }

    if (typeText == 'b' ||
        typeText.endsWith('.b') ||
        typeText.contains('bishop')) {
      return 'B';
    }

    if (typeText == 'r' ||
        typeText.endsWith('.r') ||
        typeText.contains('rook')) {
      return 'R';
    }

    if (typeText == 'q' ||
        typeText.endsWith('.q') ||
        typeText.contains('queen')) {
      return 'Q';
    }

    if (typeText == 'k' ||
        typeText.endsWith('.k') ||
        typeText.contains('king')) {
      return 'K';
    }

    return 'P';
  }

  Future<void> _handleSquareTap(String square) async {
    if (_suppressNextSquareTap) {
      _suppressNextSquareTap = false;
      return;
    }

    if (widget.annotationModeEnabled) {
      widget.onClearAnnotations?.call();
    }

    await widget.onSquareTap(square);
  }

  void _setHoveredDragTargetSquare(String? square) {
    if (_hoveredDragTargetSquare == square) {
      return;
    }

    setState(() {
      _hoveredDragTargetSquare = square;
    });
  }

  Offset _squareCenter(String square, double squareSize) {
    final file = square.substring(0, 1);
    final rank = int.parse(square.substring(1, 2));
    final fileIndex = _files.indexOf(file);

    final column = widget.playerIsWhite ? fileIndex : 7 - fileIndex;
    final row = widget.playerIsWhite ? 8 - rank : rank - 1;

    return Offset((column + 0.5) * squareSize, (row + 0.5) * squareSize);
  }

  String? _squareFromLocalPosition({
    required Offset position,
    required double boardSize,
  }) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= boardSize ||
        position.dy >= boardSize) {
      return null;
    }

    final squareSize = boardSize / 8.0;
    final column = (position.dx / squareSize).floor().clamp(0, 7);
    final row = (position.dy / squareSize).floor().clamp(0, 7);

    final fileIndex = widget.playerIsWhite ? column : 7 - column;
    final rank = widget.playerIsWhite ? 8 - row : row + 1;

    return '${_files[fileIndex]}$rank';
  }

  void _suppressFollowingSquareTapBriefly() {
    _suppressNextSquareTap = true;

    Timer(const Duration(milliseconds: 160), () {
      _suppressNextSquareTap = false;
    });
  }

  void _handlePointerDown(PointerDownEvent event, double boardSize) {
    if (!widget.annotationModeEnabled) {
      return;
    }

    final square = _squareFromLocalPosition(
      position: event.localPosition,
      boardSize: boardSize,
    );

    if (square == null) {
      return;
    }

    _annotationLongPressTimer?.cancel();
    _annotationPointer = event.pointer;
    _annotationPointerStartPosition = event.localPosition;
    _annotationDragStartSquare = square;
    _annotationDragCurrentSquare = square;
    _annotationPointerMoved = false;
    _annotationLongPressTriggered = false;

    _annotationLongPressTimer = Timer(_annotationLongPressDuration, () {
      if (!mounted ||
          !widget.annotationModeEnabled ||
          _annotationPointer != event.pointer ||
          _annotationPointerMoved ||
          _annotationDragStartSquare == null) {
        return;
      }

      _suppressFollowingSquareTapBriefly();
      _annotationLongPressTriggered = true;
      widget.onToggleAnnotationSquare?.call(_annotationDragStartSquare!);
      _resetAnnotationDragPreviewOnly();
    });
  }

  void _handlePointerMove(PointerMoveEvent event, double boardSize) {
    if (!widget.annotationModeEnabled || _annotationPointer != event.pointer) {
      return;
    }

    final startPosition = _annotationPointerStartPosition;
    if (startPosition == null || _annotationDragStartSquare == null) {
      return;
    }

    final movement = event.localPosition - startPosition;
    if (!_annotationPointerMoved &&
        movement.distance >= _annotationDragStartThreshold) {
      _annotationPointerMoved = true;
      _annotationLongPressTimer?.cancel();
    }

    if (!_annotationPointerMoved) {
      return;
    }

    final square = _squareFromLocalPosition(
      position: event.localPosition,
      boardSize: boardSize,
    );

    if (square == null || square == _annotationDragCurrentSquare) {
      return;
    }

    setState(() {
      _annotationDragCurrentSquare = square;
    });
  }

  void _handlePointerUp(PointerUpEvent event, double boardSize) {
    if (!widget.annotationModeEnabled || _annotationPointer != event.pointer) {
      _resetAnnotationGestureState();
      return;
    }

    _annotationLongPressTimer?.cancel();

    if (_annotationLongPressTriggered) {
      _suppressFollowingSquareTapBriefly();
      _resetAnnotationGestureState();
      return;
    }

    final from = _annotationDragStartSquare;
    final to = _squareFromLocalPosition(
          position: event.localPosition,
          boardSize: boardSize,
        ) ??
        _annotationDragCurrentSquare;

    if (_annotationPointerMoved && from != null && to != null && from != to) {
      widget.onToggleAnnotationArrow?.call(
        BoardArrowAnnotation(from: from, to: to),
      );
      _resetAnnotationGestureState();
      return;
    }

    // Einfacher Tap auf dem Brett löscht nur Brett-Markierungen. Der eigentliche
    // Click-to-move-Tap läuft danach weiterhin über die Squares.
    widget.onClearAnnotations?.call();
    _resetAnnotationGestureState();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_annotationPointer != event.pointer) {
      return;
    }

    _resetAnnotationGestureState();
  }

  void _resetAnnotationGestureState() {
    _annotationLongPressTimer?.cancel();
    _annotationPointer = null;
    _annotationPointerStartPosition = null;
    _annotationPointerMoved = false;
    _annotationLongPressTriggered = false;
    _resetAnnotationDragPreviewOnly();
  }

  void _resetAnnotationDragPreviewOnly() {
    if (_annotationDragStartSquare == null &&
        _annotationDragCurrentSquare == null) {
      return;
    }

    setState(() {
      _annotationDragStartSquare = null;
      _annotationDragCurrentSquare = null;
    });
  }

  BoardArrowAnnotation? get _previewArrow {
    final from = _annotationDragStartSquare;
    final to = _annotationDragCurrentSquare;

    if (!widget.annotationModeEnabled ||
        !_annotationPointerMoved ||
        from == null ||
        to == null ||
        from == to) {
      return null;
    }

    return BoardArrowAnnotation(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final squareSize = boardSize / 8.0;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _handlePointerDown(event, boardSize),
          onPointerMove: (event) => _handlePointerMove(event, boardSize),
          onPointerUp: (event) => _handlePointerUp(event, boardSize),
          onPointerCancel: _handlePointerCancel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildBoardTextureLayer()),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MobileBoardCoordinatePainter(
                      playerIsWhite: widget.playerIsWhite,
                    ),
                  ),
                ),
              ),
              GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) {
                  final square = _squareForIndex(index);
                  final piece = widget.pieceAt(square);
                  final pieceCode = _pieceCodeForPiece(piece);

                  return MobileChessBoardSquare(
                    square: square,
                    isLightSquare: _isLightSquare(square),
                    isAnalysisMode: widget.isAnalysisMode,
                    pieceCode: pieceCode,
                    highlights: widget.highlights,
                    canDrag: !widget.isAnalysisMode && widget.canHumanMovePiece(square),
                    canMoveTo: widget.canMoveTo,
                    onSquareTap: _handleSquareTap,
                    onMove: widget.onMove,
                    onPieceDragStarted: widget.onPieceDragStarted,
                    onPieceDragEnded: widget.onPieceDragEnded,
                    onDragTargetHoverChanged: _setHoveredDragTargetSquare,
                  );
                },
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MobileBoardAnnotationPainter(
                      playerIsWhite: widget.playerIsWhite,
                      markedSquares: widget.annotationMarkedSquares,
                      arrows: widget.annotationArrows,
                      previewArrow: _previewArrow,
                    ),
                  ),
                ),
              ),
              if (_hoveredDragTargetSquare != null)
                _MobileDragHoverCircle(
                  center: _squareCenter(_hoveredDragTargetSquare!, squareSize),
                  radius: squareSize * _dragHoverCircleRadiusInSquares,
                ),
            ],
          ),
        );
      },
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

    return ColorFiltered(
      colorFilter: _analysisBoardTextureColorFilter,
      child: image,
    );
  }
}


class _MobileBoardCoordinatePainter extends CustomPainter {
  const _MobileBoardCoordinatePainter({required this.playerIsWhite});

  final bool playerIsWhite;

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = math.min(size.width, size.height);
    final squareSize = boardSize / 8.0;
    final fontSize = (squareSize * 0.15).clamp(7.0, 12.0).toDouble();
    final inset = (squareSize * 0.05).clamp(2.5, 5.0).toDouble();

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
  bool shouldRepaint(covariant _MobileBoardCoordinatePainter oldDelegate) {
    return oldDelegate.playerIsWhite != playerIsWhite;
  }
}

class _MobileDragHoverCircle extends StatelessWidget {
  const _MobileDragHoverCircle({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2.0;

    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(48),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _MobileBoardAnnotationPainter extends CustomPainter {
  const _MobileBoardAnnotationPainter({
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
    final boardSize = math.min(size.width, size.height);
    final squareSize = boardSize / 8.0;
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
  bool shouldRepaint(covariant _MobileBoardAnnotationPainter oldDelegate) {
    return oldDelegate.playerIsWhite != playerIsWhite ||
        oldDelegate.markedSquares != markedSquares ||
        oldDelegate.arrows != arrows ||
        oldDelegate.previewArrow != previewArrow;
  }
}
