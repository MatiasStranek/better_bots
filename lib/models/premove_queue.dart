import 'board_move.dart';

class PremoveQueue {
  final List<BoardMove> _moves = [];

  List<BoardMove> get moves {
    return List.unmodifiable(_moves);
  }

  bool get isEmpty {
    return _moves.isEmpty;
  }

  bool get isNotEmpty {
    return _moves.isNotEmpty;
  }

  int get length {
    return _moves.length;
  }

  BoardMove? get first {
    if (_moves.isEmpty) {
      return null;
    }

    return _moves.first;
  }

  BoardMove? get last {
    if (_moves.isEmpty) {
      return null;
    }

    return _moves.last;
  }

  Set<String> get highlightedSquares {
    final squares = <String>{};

    for (final move in _moves) {
      squares.add(move.from);
      squares.add(move.to);
    }

    return squares;
  }

  String get displayText {
    if (_moves.isEmpty) {
      return '-';
    }

    return _moves.map(_moveDisplayText).join(', ');
  }

  void add(BoardMove move) {
    _moves.add(move);
  }

  void replaceWith(BoardMove move) {
    _moves
      ..clear()
      ..add(move);
  }

  BoardMove? popFirst() {
    if (_moves.isEmpty) {
      return null;
    }

    return _moves.removeAt(0);
  }

  BoardMove? removeLast() {
    if (_moves.isEmpty) {
      return null;
    }

    return _moves.removeLast();
  }

  void removeFromIndex(int index) {
    if (index < 0 || index >= _moves.length) {
      return;
    }

    _moves.removeRange(index, _moves.length);
  }

  void clear() {
    _moves.clear();
  }

  String _moveDisplayText(BoardMove move) {
    final promotion = move.promotion;

    if (promotion == null || promotion.isEmpty) {
      return '${move.from}-${move.to}';
    }

    return '${move.from}-${move.to}=${promotion.toUpperCase()}';
  }

  @override
  String toString() {
    return displayText;
  }
}
