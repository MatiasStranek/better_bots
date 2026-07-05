import 'dart:math';

import '../../models/bot_personality.dart';
import 'persona_move_candidate.dart';

class PersonaMoveSelector {
  const PersonaMoveSelector();

  String selectMove({
    required String fen,
    required List<PersonaMoveCandidate> candidates,
    required BotPersonality personality,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    final validCandidates =
        candidates.where((candidate) => candidate.isValidMove).toList()
          ..sort((a, b) {
            final byMultiPv = a.multiPv.compareTo(b.multiPv);
            if (byMultiPv != 0) {
              return byMultiPv;
            }

            return b.scoreCp.compareTo(a.scoreCp);
          });

    if (validCandidates.isEmpty) {
      return '(none)';
    }

    if (personality == BotPersonality.none ||
        personality == BotPersonality.random) {
      return validCandidates.first.uciMove;
    }

    final bestCandidate = validCandidates.first;
    final allowedLoss = _allowedCentipawnLoss(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    final playableCandidates = validCandidates.where((candidate) {
      final loss = candidate.centipawnLossComparedTo(bestCandidate);
      return loss <= allowedLoss;
    }).toList();

    final selectionPool = playableCandidates.isEmpty
        ? <PersonaMoveCandidate>[bestCandidate]
        : playableCandidates;

    final boardBefore = _MiniBoard.fromFen(fen);
    final botColor = boardBefore.sideToMove;

    final beforeFeatures = _PositionFeatures.fromBoard(
      boardBefore,
      perspective: botColor,
    );

    final scores = <_ScoredPersonaMove>[];

    for (final candidate in selectionPool) {
      final boardAfter = boardBefore.afterUciMove(candidate.uciMove);

      final afterFeatures = _PositionFeatures.fromBoard(
        boardAfter,
        perspective: botColor,
      );

      final featureDelta = afterFeatures.deltaFrom(beforeFeatures);

      final styleScore = _styleScore(
        personality: personality,
        candidate: candidate,
        bestCandidate: bestCandidate,
        before: beforeFeatures,
        after: afterFeatures,
        delta: featureDelta,
      );

      final enginePenalty = candidate.centipawnLossComparedTo(bestCandidate);

      final finalScore =
          styleScore -
          enginePenalty *
              _enginePenaltyWeight(
                skillLevel: skillLevel,
                useUciElo: useUciElo,
                uciElo: uciElo,
              );

      scores.add(
        _ScoredPersonaMove(
          candidate: candidate,
          score: finalScore,
          styleScore: styleScore,
          enginePenalty: enginePenalty,
        ),
      );
    }

    scores.sort((a, b) => b.score.compareTo(a.score));

    return scores.first.candidate.uciMove;
  }

  int _allowedCentipawnLoss({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    final strength = _strength01(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    const maxLossAtWeakest = 260.0;
    const maxLossAtStrongest = 45.0;

    return (maxLossAtWeakest -
            (maxLossAtWeakest - maxLossAtStrongest) * strength)
        .round();
  }

  double _enginePenaltyWeight({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    final strength = _strength01(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    return 0.35 + strength * 0.45;
  }

  double _strength01({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    if (!useUciElo) {
      return skillLevel.clamp(0, 20) / 20.0;
    }

    final safeElo = uciElo.clamp(1320, 3190);
    return (((safeElo - 1320) / (3190 - 1320)).clamp(0.0, 1.0)).toDouble();
  }

  double _styleScore({
    required BotPersonality personality,
    required PersonaMoveCandidate candidate,
    required PersonaMoveCandidate bestCandidate,
    required _PositionFeatures before,
    required _PositionFeatures after,
    required _FeatureDelta delta,
  }) {
    if (personality == BotPersonality.mediator) {
      return _mediatorStyleScore(
        candidate: candidate,
        bestCandidate: bestCandidate,
        before: before,
        after: after,
        delta: delta,
      );
    }

    final aggressionScore = delta.aggression;
    final complexityScore = delta.complexity;

    final safetyScore = delta.safety;
    final simplificationScore = delta.simplification;
    final initiativeScore = delta.initiative;
    final riskScore = delta.risk;

    final aggressionAxis = personality.aggression;
    final complexityAxis = personality.complexity;

    final defensiveAxis = -aggressionAxis;
    final simplificationAxis = -complexityAxis;

    return 0.0 +
        aggressionAxis * aggressionScore * 1.35 +
        defensiveAxis * safetyScore * 1.20 +
        complexityAxis * complexityScore * 1.15 +
        simplificationAxis * simplificationScore * 1.00 +
        aggressionAxis * initiativeScore * 0.90 -
        defensiveAxis.abs() * riskScore * 0.75 -
        max(0.0, aggressionAxis) * riskScore * 0.35;
  }

  double _mediatorStyleScore({
    required PersonaMoveCandidate candidate,
    required PersonaMoveCandidate bestCandidate,
    required _PositionFeatures before,
    required _PositionFeatures after,
    required _FeatureDelta delta,
  }) {
    final isClearlyBetter = bestCandidate.scoreCp >= 90;
    final isClearlyWorse = bestCandidate.scoreCp <= -90;
    final enemyKingIsWeak = before.enemyKingPressure >= 35;
    final ownKingIsUnsafe = before.ownKingPressure >= 35;

    var score = 0.0;

    score += delta.safety * 0.85;
    score += delta.initiative * 0.85;
    score += delta.aggression * 0.75;
    score -= delta.risk * 0.65;

    if (isClearlyBetter) {
      score += delta.simplification * 1.25;
      score -= delta.complexity * 0.55;
    } else if (isClearlyWorse) {
      score += delta.complexity * 1.15;
      score += delta.initiative * 0.75;
    }

    if (enemyKingIsWeak) {
      score += delta.aggression * 1.00;
      score += delta.initiative * 0.75;
    }

    if (ownKingIsUnsafe) {
      score += delta.safety * 1.15;
      score -= delta.risk * 0.90;
    }

    return score;
  }
}

class _ScoredPersonaMove {
  const _ScoredPersonaMove({
    required this.candidate,
    required this.score,
    required this.styleScore,
    required this.enginePenalty,
  });

  final PersonaMoveCandidate candidate;
  final double score;
  final double styleScore;
  final int enginePenalty;
}

class _FeatureDelta {
  const _FeatureDelta({
    required this.aggression,
    required this.safety,
    required this.simplification,
    required this.complexity,
    required this.initiative,
    required this.risk,
  });

  final double aggression;
  final double safety;
  final double simplification;
  final double complexity;
  final double initiative;
  final double risk;
}

class _PositionFeatures {
  const _PositionFeatures({
    required this.perspective,
    required this.aggression,
    required this.safety,
    required this.simplification,
    required this.complexity,
    required this.initiative,
    required this.risk,
    required this.enemyKingPressure,
    required this.ownKingPressure,
  });

  factory _PositionFeatures.fromBoard(
    _MiniBoard board, {
    required _MiniColor perspective,
  }) {
    final enemy = perspective.opposite;

    final ownKingPressure = board.kingPressureAgainst(perspective);
    final enemyKingPressure = board.kingPressureAgainst(enemy);

    final ownHangingPieces = board.hangingPieceCount(perspective);
    final enemyHangingPieces = board.hangingPieceCount(enemy);

    final pseudoChecks = board.pseudoCheckingMoveCount(perspective);
    final pseudoCaptures = board.pseudoCaptureCount(perspective);

    final nonPawnMaterial = board.nonPawnMaterialCount;
    final pawnTension = board.pawnTensionCount;
    final materialImbalance = board.materialImbalanceAbs;

    final ownMobility = board.mobilityScore(perspective);
    final enemyMobility = board.mobilityScore(enemy);

    final aggression =
        enemyKingPressure * 1.25 +
        enemyHangingPieces * 16.0 +
        pseudoChecks * 18.0 +
        pseudoCaptures * 3.5 +
        board.activePieceScore(perspective) * 0.35;

    final safety =
        board.kingShieldScore(perspective) * 12.0 -
        ownKingPressure * 1.25 -
        ownHangingPieces * 18.0 +
        board.defendedPieceCount(perspective) * 2.0;

    final simplification =
        (32 - nonPawnMaterial) * 4.0 - pseudoCaptures * 2.0 - pawnTension * 2.5;

    final complexity =
        nonPawnMaterial * 3.0 +
        pawnTension * 8.0 +
        materialImbalance * 0.08 +
        pseudoCaptures * 4.5 +
        pseudoChecks * 6.0 +
        (ownHangingPieces + enemyHangingPieces) * 10.0;

    final initiative =
        pseudoChecks * 20.0 +
        pseudoCaptures * 5.0 +
        enemyHangingPieces * 18.0 +
        ownMobility * 0.55 -
        enemyMobility * 0.35;

    final risk =
        ownKingPressure * 1.30 +
        ownHangingPieces * 18.0 +
        max(0.0, enemyMobility - ownMobility) * 0.30;

    return _PositionFeatures(
      perspective: perspective,
      aggression: aggression,
      safety: safety,
      simplification: simplification,
      complexity: complexity,
      initiative: initiative,
      risk: risk,
      enemyKingPressure: enemyKingPressure,
      ownKingPressure: ownKingPressure,
    );
  }

  final _MiniColor perspective;

  final double aggression;
  final double safety;
  final double simplification;
  final double complexity;
  final double initiative;
  final double risk;

  final double enemyKingPressure;
  final double ownKingPressure;

  _FeatureDelta deltaFrom(_PositionFeatures before) {
    return _FeatureDelta(
      aggression: aggression - before.aggression,
      safety: safety - before.safety,
      simplification: simplification - before.simplification,
      complexity: complexity - before.complexity,
      initiative: initiative - before.initiative,
      risk: risk - before.risk,
    );
  }
}

enum _MiniColor {
  white,
  black;

  _MiniColor get opposite {
    return this == _MiniColor.white ? _MiniColor.black : _MiniColor.white;
  }
}

class _MiniPiece {
  const _MiniPiece(this.type, this.color);

  final String type;
  final _MiniColor color;

  bool get isPawn => type == 'p';
  bool get isKnight => type == 'n';
  bool get isBishop => type == 'b';
  bool get isRook => type == 'r';
  bool get isQueen => type == 'q';
  bool get isKing => type == 'k';

  int get materialValue {
    switch (type) {
      case 'p':
        return 100;
      case 'n':
        return 320;
      case 'b':
        return 330;
      case 'r':
        return 500;
      case 'q':
        return 900;
      default:
        return 0;
    }
  }
}

class _MiniBoard {
  _MiniBoard({required this.squares, required this.sideToMove});

  factory _MiniBoard.fromFen(String fen) {
    final normalizedFen = fen == 'startpos'
        ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
        : fen;

    final parts = normalizedFen.split(' ');
    final placement = parts.isNotEmpty ? parts[0] : '8/8/8/8/8/8/8/8';
    final activeColor = parts.length >= 2 ? parts[1] : 'w';

    final squares = List<_MiniPiece?>.filled(64, null);
    final ranks = placement.split('/');

    for (var fenRank = 0; fenRank < min(8, ranks.length); fenRank++) {
      var file = 0;

      for (final char in ranks[fenRank].split('')) {
        final digit = int.tryParse(char);

        if (digit != null) {
          file += digit;
          continue;
        }

        if (file >= 8) {
          continue;
        }

        final color = char == char.toUpperCase()
            ? _MiniColor.white
            : _MiniColor.black;
        final type = char.toLowerCase();

        final boardRank = 7 - fenRank;
        final index = boardRank * 8 + file;

        squares[index] = _MiniPiece(type, color);
        file++;
      }
    }

    return _MiniBoard(
      squares: squares,
      sideToMove: activeColor == 'b' ? _MiniColor.black : _MiniColor.white,
    );
  }

  final List<_MiniPiece?> squares;
  final _MiniColor sideToMove;

  _MiniBoard afterUciMove(String uciMove) {
    if (uciMove.length < 4) {
      return this;
    }

    final from = _squareIndex(uciMove.substring(0, 2));
    final to = _squareIndex(uciMove.substring(2, 4));

    if (from == null || to == null) {
      return this;
    }

    final newSquares = List<_MiniPiece?>.from(squares);
    final movingPiece = newSquares[from];

    if (movingPiece == null) {
      return _MiniBoard(squares: newSquares, sideToMove: sideToMove.opposite);
    }

    var finalPiece = movingPiece;

    final fromFile = from % 8;
    final toFile = to % 8;

    if (movingPiece.isPawn && newSquares[to] == null && fromFile != toFile) {
      final capturedPawnSquare = movingPiece.color == _MiniColor.white
          ? to - 8
          : to + 8;

      if (capturedPawnSquare >= 0 && capturedPawnSquare < 64) {
        final capturedPiece = newSquares[capturedPawnSquare];
        if (capturedPiece != null &&
            capturedPiece.color != movingPiece.color &&
            capturedPiece.isPawn) {
          newSquares[capturedPawnSquare] = null;
        }
      }
    }

    if (uciMove.length >= 5 && movingPiece.isPawn) {
      final promotion = uciMove.substring(4, 5).toLowerCase();
      if (['q', 'r', 'b', 'n'].contains(promotion)) {
        finalPiece = _MiniPiece(promotion, movingPiece.color);
      }
    }

    newSquares[from] = null;
    newSquares[to] = finalPiece;

    if (movingPiece.isKing && (from - to).abs() == 2) {
      _applyCastlingRookMove(
        newSquares: newSquares,
        kingFrom: from,
        kingTo: to,
        color: movingPiece.color,
      );
    }

    return _MiniBoard(squares: newSquares, sideToMove: sideToMove.opposite);
  }

  void _applyCastlingRookMove({
    required List<_MiniPiece?> newSquares,
    required int kingFrom,
    required int kingTo,
    required _MiniColor color,
  }) {
    final isWhite = color == _MiniColor.white;

    if (isWhite && kingFrom == 4 && kingTo == 6) {
      newSquares[7] = null;
      newSquares[5] = _MiniPiece('r', color);
      return;
    }

    if (isWhite && kingFrom == 4 && kingTo == 2) {
      newSquares[0] = null;
      newSquares[3] = _MiniPiece('r', color);
      return;
    }

    if (!isWhite && kingFrom == 60 && kingTo == 62) {
      newSquares[63] = null;
      newSquares[61] = _MiniPiece('r', color);
      return;
    }

    if (!isWhite && kingFrom == 60 && kingTo == 58) {
      newSquares[56] = null;
      newSquares[59] = _MiniPiece('r', color);
    }
  }

  int get nonPawnMaterialCount {
    var count = 0;

    for (final piece in squares) {
      if (piece == null || piece.isPawn || piece.isKing) {
        continue;
      }

      count++;
    }

    return count;
  }

  int get materialImbalanceAbs {
    var white = 0;
    var black = 0;

    for (final piece in squares) {
      if (piece == null) {
        continue;
      }

      if (piece.color == _MiniColor.white) {
        white += piece.materialValue;
      } else {
        black += piece.materialValue;
      }
    }

    return (white - black).abs();
  }

  int get pawnTensionCount {
    var count = 0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || !piece.isPawn) {
        continue;
      }

      final attacks = _attackedSquaresByPiece(i, piece);
      for (final target in attacks) {
        final targetPiece = squares[target];
        if (targetPiece != null &&
            targetPiece.color != piece.color &&
            targetPiece.isPawn) {
          count++;
        }
      }
    }

    return count;
  }

  double kingPressureAgainst(_MiniColor kingColor) {
    final kingIndex = _kingIndex(kingColor);

    if (kingIndex == null) {
      return 0;
    }

    final attacker = kingColor.opposite;
    final zone = _kingZone(kingIndex);

    var pressure = 0.0;

    for (final square in zone) {
      final attackers = attackersOf(attacker, square);
      for (final attackerIndex in attackers) {
        final piece = squares[attackerIndex];
        if (piece == null) {
          continue;
        }

        pressure += _attackWeight(piece);
      }
    }

    return pressure;
  }

  int hangingPieceCount(_MiniColor color) {
    var count = 0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color || piece.isKing) {
        continue;
      }

      final defenders = attackersOf(color, i);
      final attackers = attackersOf(color.opposite, i);

      if (attackers.isNotEmpty && defenders.isEmpty) {
        count++;
      }
    }

    return count;
  }

  int defendedPieceCount(_MiniColor color) {
    var count = 0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color || piece.isKing) {
        continue;
      }

      if (attackersOf(color, i).isNotEmpty) {
        count++;
      }
    }

    return count;
  }

  int pseudoCaptureCount(_MiniColor color) {
    var count = 0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color) {
        continue;
      }

      final attacks = _attackedSquaresByPiece(i, piece);

      for (final target in attacks) {
        final targetPiece = squares[target];

        if (targetPiece != null && targetPiece.color != color) {
          count++;
        }
      }
    }

    return count;
  }

  int pseudoCheckingMoveCount(_MiniColor color) {
    final enemyKing = _kingIndex(color.opposite);

    if (enemyKing == null) {
      return 0;
    }

    var count = 0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color) {
        continue;
      }

      final attacks = _attackedSquaresByPiece(i, piece);

      if (attacks.contains(enemyKing)) {
        count++;
      }
    }

    return count;
  }

  double activePieceScore(_MiniColor color) {
    var score = 0.0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color || piece.isKing) {
        continue;
      }

      final rank = i ~/ 8;
      final file = i % 8;

      final centerDistance = (file - 3.5).abs() + (rank - 3.5).abs();

      score += max(0.0, 7.0 - centerDistance);

      if (color == _MiniColor.white && rank >= 4) {
        score += 2.0;
      }

      if (color == _MiniColor.black && rank <= 3) {
        score += 2.0;
      }
    }

    return score;
  }

  double mobilityScore(_MiniColor color) {
    var score = 0.0;

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color) {
        continue;
      }

      score += _attackedSquaresByPiece(i, piece).length;
    }

    return score;
  }

  double kingShieldScore(_MiniColor color) {
    final king = _kingIndex(color);

    if (king == null) {
      return 0;
    }

    final kingRank = king ~/ 8;
    final kingFile = king % 8;

    final shieldRank = color == _MiniColor.white ? kingRank + 1 : kingRank - 1;

    if (shieldRank < 0 || shieldRank > 7) {
      return 0;
    }

    var shield = 0.0;

    for (final file in [kingFile - 1, kingFile, kingFile + 1]) {
      if (file < 0 || file > 7) {
        continue;
      }

      final piece = squares[shieldRank * 8 + file];

      if (piece != null && piece.color == color && piece.isPawn) {
        shield += 1.0;
      }
    }

    return shield;
  }

  List<int> attackersOf(_MiniColor color, int targetSquare) {
    final result = <int>[];

    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece == null || piece.color != color) {
        continue;
      }

      if (_attackedSquaresByPiece(i, piece).contains(targetSquare)) {
        result.add(i);
      }
    }

    return result;
  }

  int? _kingIndex(_MiniColor color) {
    for (var i = 0; i < 64; i++) {
      final piece = squares[i];

      if (piece != null && piece.color == color && piece.isKing) {
        return i;
      }
    }

    return null;
  }

  List<int> _kingZone(int kingIndex) {
    final zone = <int>{kingIndex};

    final rank = kingIndex ~/ 8;
    final file = kingIndex % 8;

    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        final nr = rank + dr;
        final nf = file + df;

        if (nr < 0 || nr > 7 || nf < 0 || nf > 7) {
          continue;
        }

        zone.add(nr * 8 + nf);
      }
    }

    return zone.toList();
  }

  double _attackWeight(_MiniPiece piece) {
    if (piece.isPawn) {
      return 3.0;
    }

    if (piece.isKnight || piece.isBishop) {
      return 6.0;
    }

    if (piece.isRook) {
      return 8.0;
    }

    if (piece.isQueen) {
      return 12.0;
    }

    return 1.0;
  }

  List<int> _attackedSquaresByPiece(int index, _MiniPiece piece) {
    if (piece.isPawn) {
      return _pawnAttacks(index, piece.color);
    }

    if (piece.isKnight) {
      return _stepAttacks(index, const [
        [1, 2],
        [2, 1],
        [2, -1],
        [1, -2],
        [-1, -2],
        [-2, -1],
        [-2, 1],
        [-1, 2],
      ]);
    }

    if (piece.isBishop) {
      return _rayAttacks(index, const [
        [1, 1],
        [1, -1],
        [-1, 1],
        [-1, -1],
      ]);
    }

    if (piece.isRook) {
      return _rayAttacks(index, const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]);
    }

    if (piece.isQueen) {
      return _rayAttacks(index, const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
        [1, 1],
        [1, -1],
        [-1, 1],
        [-1, -1],
      ]);
    }

    if (piece.isKing) {
      return _stepAttacks(index, const [
        [1, 0],
        [1, 1],
        [0, 1],
        [-1, 1],
        [-1, 0],
        [-1, -1],
        [0, -1],
        [1, -1],
      ]);
    }

    return const [];
  }

  List<int> _pawnAttacks(int index, _MiniColor color) {
    final rank = index ~/ 8;
    final file = index % 8;
    final direction = color == _MiniColor.white ? 1 : -1;

    final attacks = <int>[];

    for (final df in [-1, 1]) {
      final nr = rank + direction;
      final nf = file + df;

      if (nr < 0 || nr > 7 || nf < 0 || nf > 7) {
        continue;
      }

      attacks.add(nr * 8 + nf);
    }

    return attacks;
  }

  List<int> _stepAttacks(int index, List<List<int>> directions) {
    final rank = index ~/ 8;
    final file = index % 8;
    final attacks = <int>[];

    for (final direction in directions) {
      final nr = rank + direction[0];
      final nf = file + direction[1];

      if (nr < 0 || nr > 7 || nf < 0 || nf > 7) {
        continue;
      }

      attacks.add(nr * 8 + nf);
    }

    return attacks;
  }

  List<int> _rayAttacks(int index, List<List<int>> directions) {
    final rank = index ~/ 8;
    final file = index % 8;
    final attacks = <int>[];

    for (final direction in directions) {
      var nr = rank + direction[0];
      var nf = file + direction[1];

      while (nr >= 0 && nr <= 7 && nf >= 0 && nf <= 7) {
        final target = nr * 8 + nf;
        attacks.add(target);

        if (squares[target] != null) {
          break;
        }

        nr += direction[0];
        nf += direction[1];
      }
    }

    return attacks;
  }

  static int? _squareIndex(String square) {
    if (square.length != 2) {
      return null;
    }

    final fileChar = square.codeUnitAt(0);
    final rankChar = square.codeUnitAt(1);

    final file = fileChar - 'a'.codeUnitAt(0);
    final rank = rankChar - '1'.codeUnitAt(0);

    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      return null;
    }

    return rank * 8 + file;
  }
}
