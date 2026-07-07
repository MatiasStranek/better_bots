import 'dart:math';

import '../../models/fritz19_personality.dart';
import 'cp_loss_move_selector.dart';
import 'persona_move_candidate.dart';

/// Eigenständige Fritz19-Stilentscheidung.
///
/// Wichtig:
/// - Das ist bewusst NICHT der Chessiverse PersonaMoveSelector.
/// - Fritz19 bleibt trotzdem nur ein Persönlichkeits-Typ und wird weiterhin
///   mit Stärke, CP_Loss_ELO, UCI_ELO, Kandidatenzahl, Eröffnung usw. kombiniert.
/// - Die Stärke/Fehlerklasse begrenzt zuerst die Kandidaten.
/// - Danach wählt Fritz19 innerhalb dieses Pools nach eigenem Stilprofil.
class Fritz19MoveSelector {
  const Fritz19MoveSelector();

  Fritz19MoveSelection selectMove({
    required String fen,
    required List<PersonaMoveCandidate> candidates,
    required Fritz19Personality personality,
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
    Random? random,
  }) {
    final validCandidates = _sortedValidCandidates(candidates);

    if (validCandidates.isEmpty) {
      return Fritz19MoveSelection.empty(personality: personality);
    }

    final bestCandidate = validCandidates.first;
    final allowedLoss = _allowedCentipawnLoss(
      skillLevel: skillLevel,
      useUciElo: useUciElo,
      uciElo: uciElo,
    );

    final playableCandidates = validCandidates.where((candidate) {
      return candidate.centipawnLossComparedTo(bestCandidate) <= allowedLoss;
    }).toList();

    return _selectFromPreparedCandidates(
      fen: fen,
      candidates: playableCandidates.isEmpty
          ? <PersonaMoveCandidate>[bestCandidate]
          : playableCandidates,
      bestCandidate: bestCandidate,
      personality: personality,
      enginePenaltyWeight: _enginePenaltyWeight(
        skillLevel: skillLevel,
        useUciElo: useUciElo,
        uciElo: uciElo,
      ),
      random: random ?? Random(),
    );
  }

  Fritz19MoveSelection selectMoveFromCpLossPool({
    required String fen,
    required CpLossCandidatePool pool,
    required Fritz19Personality personality,
    Random? random,
  }) {
    final validCandidates = _sortedValidCandidates(pool.candidates);

    if (validCandidates.isEmpty) {
      return Fritz19MoveSelection.empty(personality: personality);
    }

    return _selectFromPreparedCandidates(
      fen: fen,
      candidates: validCandidates,
      bestCandidate: pool.bestCandidate ?? validCandidates.first,
      personality: personality,
      // CP_Loss_ELO hat den Qualitätskorridor bereits gebaut.
      // Deshalb hier nur sehr leicht objektiv bestrafen und stärker Stil wählen.
      enginePenaltyWeight: 0.08,
      random: random ?? Random(),
    );
  }

  List<PersonaMoveCandidate> _sortedValidCandidates(
    List<PersonaMoveCandidate> candidates,
  ) {
    return candidates.where((candidate) => candidate.isValidMove).toList()
      ..sort((a, b) {
        final byMultiPv = a.multiPv.compareTo(b.multiPv);
        if (byMultiPv != 0) {
          return byMultiPv;
        }

        return b.scoreCp.compareTo(a.scoreCp);
      });
  }

  Fritz19MoveSelection _selectFromPreparedCandidates({
    required String fen,
    required List<PersonaMoveCandidate> candidates,
    required PersonaMoveCandidate bestCandidate,
    required Fritz19Personality personality,
    required double enginePenaltyWeight,
    required Random random,
  }) {
    final effectivePersonality = personality == Fritz19Personality.random
        ? Fritz19Personality.allrounder
        : personality;

    final board = _FritzBoard.fromFen(fen);
    final scoredMoves = <_ScoredFritz19Move>[];

    for (final candidate in candidates) {
      final features = _Fritz19MoveFeatures.fromCandidate(
        board: board,
        candidate: candidate,
        bestCandidate: bestCandidate,
      );

      final profileScores = _profileScores(features);
      final styleScore = effectivePersonality.isAbstract
          ? _abstractStyleScore(features, profileScores)
          : _styleScore(personality: effectivePersonality, features: features);

      final finalScore =
          styleScore - features.engineLoss * enginePenaltyWeight;

      scoredMoves.add(
        _ScoredFritz19Move(
          candidate: candidate,
          features: features,
          styleScore: styleScore,
          score: finalScore,
          reason: _reasonFor(
            personality: effectivePersonality,
            features: features,
            profileScores: profileScores,
          ),
        ),
      );
    }

    if (scoredMoves.isEmpty) {
      return Fritz19MoveSelection.empty(personality: effectivePersonality);
    }

    scoredMoves.sort((a, b) => b.score.compareTo(a.score));

    final chosen = _humanLikePick(scoredMoves, random: random);

    return Fritz19MoveSelection(
      uciMove: chosen.candidate.uciMove,
      personality: effectivePersonality,
      styleScore: chosen.styleScore,
      engineLoss: chosen.features.engineLoss.round(),
      candidateCount: candidates.length,
      reason: chosen.reason,
    );
  }

  _ScoredFritz19Move _humanLikePick(
    List<_ScoredFritz19Move> scoredMoves, {
    required Random random,
  }) {
    if (scoredMoves.length <= 1) {
      return scoredMoves.first;
    }

    final bestScore = scoredMoves.first.score;

    final pool = scoredMoves.where((move) {
      return move.score >= bestScore - 24.0;
    }).take(4).toList();

    final choices = pool.isEmpty ? scoredMoves.take(1).toList() : pool;
    final weights = <double>[];
    var totalWeight = 0.0;

    for (final move in choices) {
      final relativeScore = move.score - bestScore;
      final weight = exp(relativeScore / 15.0).clamp(0.035, 1.0).toDouble();

      weights.add(weight);
      totalWeight += weight;
    }

    var roll = random.nextDouble() * totalWeight;

    for (var i = 0; i < choices.length; i++) {
      roll -= weights[i];

      if (roll <= 0) {
        return choices[i];
      }
    }

    return choices.first;
  }

  Map<Fritz19Personality, double> _profileScores(
    _Fritz19MoveFeatures features,
  ) {
    return {
      Fritz19Personality.allrounder: _allrounderScore(features),
      Fritz19Personality.attacker: _attackerScore(features),
      Fritz19Personality.swindler: _swindlerScore(features),
      Fritz19Personality.positional: _positionalScore(features),
      Fritz19Personality.timid: _timidScore(features),
      Fritz19Personality.endgameCrack: _endgameCrackScore(features),
    };
  }

  double _styleScore({
    required Fritz19Personality personality,
    required _Fritz19MoveFeatures features,
  }) {
    switch (personality) {
      case Fritz19Personality.random:
      case Fritz19Personality.allrounder:
        return _allrounderScore(features);
      case Fritz19Personality.attacker:
        return _attackerScore(features);
      case Fritz19Personality.swindler:
        return _swindlerScore(features);
      case Fritz19Personality.positional:
        return _positionalScore(features);
      case Fritz19Personality.timid:
        return _timidScore(features);
      case Fritz19Personality.endgameCrack:
        return _endgameCrackScore(features);
      case Fritz19Personality.abstractStyle:
        return _abstractStyleScore(features, _profileScores(features));
    }
  }

  double _allrounderScore(_Fritz19MoveFeatures f) {
    // Natürlich, wenig extrem, guter Zug bleibt wichtig.
    return f.engineQualityBonus * 0.54 +
        f.centerGain * 10.0 +
        f.developmentBonus * 12.0 +
        (f.givesCheck ? 8.0 : 0.0) +
        (f.isCapture ? 7.0 : 0.0) +
        f.quietMoveBonus * 5.0 -
        f.excessiveRisk * 18.0 -
        f.engineLoss * 0.16;
  }

  double _attackerScore(_Fritz19MoveFeatures f) {
    // Königsdruck und Initiative, Vereinfachung wird gemieden.
    return (f.givesCheck ? 54.0 : 0.0) +
        f.movesTowardEnemyKing * 30.0 +
        f.attackLineBonus * 22.0 +
        (f.isCapture ? 16.0 : 0.0) +
        (f.isPromotion ? 30.0 : 0.0) -
        (f.isQueenTrade ? 30.0 : 0.0) -
        f.quietMoveBonus * 6.0 -
        f.engineLoss * 0.07;
  }

  double _swindlerScore(_Fritz19MoveFeatures f) {
    // Wenn schlechter, bewusst unangenehm/chaotisch statt brav.
    final behindMultiplier = f.isBehind ? 1.45 : 0.78;

    return (f.isBehind ? 30.0 : 0.0) +
        (f.givesCheck ? 32.0 : 0.0) +
        (f.isCapture ? 19.0 : 0.0) +
        (f.isPromotion ? 28.0 : 0.0) +
        f.nonBestMoveBonus * behindMultiplier +
        f.complexityBonus * 36.0 +
        f.movesTowardEnemyKing * 17.0 -
        (f.isQueenTrade ? 18.0 : 0.0);
  }

  double _positionalScore(_Fritz19MoveFeatures f) {
    // Zentrum, Entwicklung, ruhige Verbesserung, weniger Chaos.
    return f.engineQualityBonus * 0.50 +
        f.centerGain * 26.0 +
        f.developmentBonus * 22.0 +
        f.quietMoveBonus * 18.0 +
        (f.isQueenTrade && f.isAhead ? 12.0 : 0.0) -
        f.complexityBonus * 12.0 -
        f.excessiveRisk * 24.0 -
        f.nonBestMoveBonus * 0.18;
  }

  double _timidScore(_Fritz19MoveFeatures f) {
    // Sicherheits- und Vereinfachungsdrang, meidet scharfe Züge.
    return f.engineQualityBonus * 0.58 +
        (f.isQueenTrade ? 30.0 : 0.0) +
        f.quietMoveBonus * 30.0 +
        f.ownKingDistanceGain * 20.0 -
        (f.givesCheck ? 13.0 : 0.0) -
        (f.isCapture ? 8.0 : 0.0) -
        f.complexityBonus * 28.0 -
        f.movesTowardEnemyKing * 7.0 -
        f.engineLoss * 0.22;
  }

  double _endgameCrackScore(_Fritz19MoveFeatures f) {
    // Tauscht gern, wird im Endspiel objektiver und priorisiert Freibauern.
    return f.endgameFactor * 34.0 +
        (f.isQueenTrade ? 42.0 : 0.0) +
        (f.isCapture ? 18.0 : 0.0) +
        (f.isPromotion ? 48.0 : 0.0) +
        f.pawnAdvanceBonus * 28.0 +
        f.engineQualityBonus * (0.34 + f.endgameFactor * 0.30) -
        f.complexityBonus * 14.0 -
        (f.givesCheck && !f.isPromotion ? 5.0 : 0.0);
  }

  double _abstractStyleScore(
    _Fritz19MoveFeatures f,
    Map<Fritz19Personality, double> profileScores,
  ) {
    // Abstract sucht bewusst das, was nicht sauber in die anderen Fritz19-Profile
    // passt. Also: weder klarer Angriff, noch klarer Tausch, noch klarer
    // Sicherheitszug. Trotzdem nicht random und nicht grenzenlos schlecht.
    final knownScores = profileScores.values.toList();
    final maxKnownScore = knownScores.reduce(max);
    final minKnownScore = knownScores.reduce(min);
    final averageKnownScore =
        knownScores.reduce((a, b) => a + b) / knownScores.length;
    final spread = maxKnownScore - minKnownScore;

    return -maxKnownScore * 0.88 -
        max(0.0, averageKnownScore) * 0.22 +
        max(0.0, 50.0 - spread) * 0.34 +
        f.nonBestMoveBonus * 0.50 +
        f.quietMoveBonus * 9.0 -
        f.excessiveRisk * 14.0;
  }

  String _reasonFor({
    required Fritz19Personality personality,
    required _Fritz19MoveFeatures features,
    required Map<Fritz19Personality, double> profileScores,
  }) {
    switch (personality) {
      case Fritz19Personality.random:
      case Fritz19Personality.allrounder:
        return 'natürlicher Kompromiss';
      case Fritz19Personality.attacker:
        if (features.givesCheck) {
          return 'Schach/Königsdruck';
        }

        return 'Angriffsdruck';
      case Fritz19Personality.swindler:
        if (features.isBehind) {
          return 'Chaos bei schlechter Stellung';
        }

        return 'Komplikation';
      case Fritz19Personality.positional:
        return 'Struktur/Zentrum';
      case Fritz19Personality.timid:
        return 'sichere Vereinfachung';
      case Fritz19Personality.endgameCrack:
        if (features.isQueenTrade) {
          return 'Damentausch/Endspiel';
        }

        return 'Endspielorientierung';
      case Fritz19Personality.abstractStyle:
        return 'passt wenig zu den anderen Profilen';
    }
  }

  int _allowedCentipawnLoss({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    if (useUciElo) {
      if (uciElo >= 2800) {
        return 35;
      }

      if (uciElo >= 2400) {
        return 70;
      }

      if (uciElo >= 2000) {
        return 120;
      }

      if (uciElo >= 1600) {
        return 220;
      }

      return 360;
    }

    if (skillLevel >= 18) {
      return 45;
    }

    if (skillLevel >= 14) {
      return 95;
    }

    if (skillLevel >= 10) {
      return 160;
    }

    if (skillLevel >= 6) {
      return 260;
    }

    return 420;
  }

  double _enginePenaltyWeight({
    required int skillLevel,
    required bool useUciElo,
    required int uciElo,
  }) {
    final strength = useUciElo
        ? ((uciElo - 1320) / (3190 - 1320)).clamp(0.0, 1.0)
        : (skillLevel / 20.0).clamp(0.0, 1.0);

    return 0.12 + strength * 0.62;
  }
}

class Fritz19MoveSelection {
  const Fritz19MoveSelection({
    required this.uciMove,
    required this.personality,
    required this.styleScore,
    required this.engineLoss,
    required this.candidateCount,
    required this.reason,
  });

  factory Fritz19MoveSelection.empty({
    required Fritz19Personality personality,
  }) {
    return Fritz19MoveSelection(
      uciMove: '(none)',
      personality: personality,
      styleScore: 0,
      engineLoss: 0,
      candidateCount: 0,
      reason: '-',
    );
  }

  final String uciMove;
  final Fritz19Personality personality;
  final double styleScore;
  final int engineLoss;
  final int candidateCount;
  final String reason;

  String get debugText {
    return 'Fritz19: ${personality.label} | '
        'Grund: $reason | '
        'Style: ${styleScore.toStringAsFixed(1)} | '
        'Loss: $engineLoss cp | '
        'Kandidaten: $candidateCount | '
        'Zug: $uciMove';
  }
}

class _ScoredFritz19Move {
  const _ScoredFritz19Move({
    required this.candidate,
    required this.features,
    required this.styleScore,
    required this.score,
    required this.reason,
  });

  final PersonaMoveCandidate candidate;
  final _Fritz19MoveFeatures features;
  final double styleScore;
  final double score;
  final String reason;
}

class _Fritz19MoveFeatures {
  const _Fritz19MoveFeatures({
    required this.engineLoss,
    required this.engineQualityBonus,
    required this.nonBestMoveBonus,
    required this.isCapture,
    required this.isPromotion,
    required this.givesCheck,
    required this.isQueenTrade,
    required this.centerGain,
    required this.developmentBonus,
    required this.movesTowardEnemyKing,
    required this.ownKingDistanceGain,
    required this.attackLineBonus,
    required this.complexityBonus,
    required this.quietMoveBonus,
    required this.pawnAdvanceBonus,
    required this.endgameFactor,
    required this.isAhead,
    required this.isBehind,
    required this.excessiveRisk,
  });

  final double engineLoss;
  final double engineQualityBonus;
  final double nonBestMoveBonus;
  final bool isCapture;
  final bool isPromotion;
  final bool givesCheck;
  final bool isQueenTrade;
  final double centerGain;
  final double developmentBonus;
  final double movesTowardEnemyKing;
  final double ownKingDistanceGain;
  final double attackLineBonus;
  final double complexityBonus;
  final double quietMoveBonus;
  final double pawnAdvanceBonus;
  final double endgameFactor;
  final bool isAhead;
  final bool isBehind;
  final double excessiveRisk;

  factory _Fritz19MoveFeatures.fromCandidate({
    required _FritzBoard board,
    required PersonaMoveCandidate candidate,
    required PersonaMoveCandidate bestCandidate,
  }) {
    final from = candidate.uciMove.substring(0, 2);
    final to = candidate.uciMove.substring(2, 4);
    final movingPiece = board.pieceAt(from);
    final capturedPiece = board.pieceAt(to);
    final afterBoard = board.afterMove(candidate.uciMove);

    final side = board.sideToMove;
    final enemy = side.opposite;

    final engineLoss = max(
      0,
      candidate.centipawnLossComparedTo(bestCandidate),
    ).toDouble();

    final fromCenterDistance = _centerDistance(from);
    final toCenterDistance = _centerDistance(to);
    final centerGain = (fromCenterDistance - toCenterDistance).clamp(-2.0, 2.0);

    final enemyKingSquare = board.kingSquare(enemy);
    final ownKingSquare = board.kingSquare(side);

    final movesTowardEnemyKing = enemyKingSquare == null
        ? 0.0
        : (_squareDistance(from, enemyKingSquare) -
                _squareDistance(to, enemyKingSquare))
            .clamp(-2.0, 2.0);

    final ownKingDistanceGain = ownKingSquare == null
        ? 0.0
        : (_squareDistance(to, ownKingSquare) -
                _squareDistance(from, ownKingSquare))
            .clamp(-2.0, 2.0);

    final givesCheck = afterBoard.isKingAttacked(enemy, by: side);
    final isCapture = capturedPiece != null;
    final isPromotion = candidate.uciMove.length >= 5;
    final pieceType = movingPiece == null ? '' : movingPiece.toLowerCase();
    final capturedType = capturedPiece == null ? '' : capturedPiece.toLowerCase();

    final isQueenTrade = pieceType == 'q' || capturedType == 'q';

    final developmentBonus = _developmentBonus(
      pieceType: pieceType,
      from: from,
      to: to,
      side: side,
    );

    final materialBefore = board.materialBalanceFor(side);
    final isAhead = materialBefore >= 3;
    final isBehind = bestCandidate.scoreCp <= -80 || materialBefore <= -3;

    final endgameFactor = board.endgameFactor;
    final pawnAdvanceBonus = pieceType == 'p'
        ? _pawnAdvanceBonus(from: from, to: to, side: side)
        : 0.0;

    final attackLineBonus = (givesCheck ? 1.0 : 0.0) +
        max(0.0, movesTowardEnemyKing.toDouble()) * 0.45 +
        (isCapture ? 0.35 : 0.0);

    final complexityBonus = (isCapture ? 0.45 : 0.0) +
        (givesCheck ? 0.45 : 0.0) +
        (isPromotion ? 0.55 : 0.0) +
        min(1.0, engineLoss / 160.0);

    final quietMoveBonus =
        !isCapture && !givesCheck && !isPromotion ? 1.0 : 0.0;

    final excessiveRisk = max(0.0, engineLoss - 90.0) / 140.0;
    final engineQualityBonus = max(0.0, 180.0 - engineLoss);
    final nonBestMoveBonus = min(120.0, engineLoss);

    return _Fritz19MoveFeatures(
      engineLoss: engineLoss,
      engineQualityBonus: engineQualityBonus,
      nonBestMoveBonus: nonBestMoveBonus,
      isCapture: isCapture,
      isPromotion: isPromotion,
      givesCheck: givesCheck,
      isQueenTrade: isQueenTrade,
      centerGain: centerGain.toDouble(),
      developmentBonus: developmentBonus,
      movesTowardEnemyKing: movesTowardEnemyKing.toDouble(),
      ownKingDistanceGain: ownKingDistanceGain.toDouble(),
      attackLineBonus: attackLineBonus,
      complexityBonus: complexityBonus,
      quietMoveBonus: quietMoveBonus,
      pawnAdvanceBonus: pawnAdvanceBonus,
      endgameFactor: endgameFactor,
      isAhead: isAhead,
      isBehind: isBehind,
      excessiveRisk: excessiveRisk,
    );
  }

  static double _centerDistance(String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square.substring(1, 2)) - 1;

    return (file - 3.5).abs() + (rank - 3.5).abs();
  }

  static double _squareDistance(String a, String b) {
    final fileA = a.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rankA = int.parse(a.substring(1, 2)) - 1;
    final fileB = b.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rankB = int.parse(b.substring(1, 2)) - 1;

    return ((fileA - fileB).abs() + (rankA - rankB).abs()).toDouble();
  }

  static double _developmentBonus({
    required String pieceType,
    required String from,
    required String to,
    required _FritzColor side,
  }) {
    if (pieceType != 'n' && pieceType != 'b') {
      return 0.0;
    }

    final homeRank = side == _FritzColor.white ? '1' : '8';

    if (!from.endsWith(homeRank)) {
      return 0.0;
    }

    return _centerDistance(from) > _centerDistance(to) ? 1.0 : 0.35;
  }

  static double _pawnAdvanceBonus({
    required String from,
    required String to,
    required _FritzColor side,
  }) {
    final fromRank = int.parse(from.substring(1, 2));
    final toRank = int.parse(to.substring(1, 2));
    final delta = side == _FritzColor.white ? toRank - fromRank : fromRank - toRank;

    if (delta <= 0) {
      return 0.0;
    }

    final promotionRank = side == _FritzColor.white ? 8 : 1;
    final distanceToPromotion = (promotionRank - toRank).abs();

    return delta * 0.35 + max(0.0, 4.0 - distanceToPromotion) * 0.22;
  }
}

class _FritzBoard {
  const _FritzBoard({
    required this.pieces,
    required this.sideToMove,
  });

  factory _FritzBoard.fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    final boardPart = parts.isEmpty ? '8/8/8/8/8/8/8/8' : parts.first;
    final sidePart = parts.length > 1 ? parts[1] : 'w';

    final pieces = <String, String>{};
    final ranks = boardPart.split('/');

    for (var rankIndex = 0; rankIndex < min(8, ranks.length); rankIndex++) {
      final rankText = ranks[rankIndex];
      var fileIndex = 0;
      final rankNumber = 8 - rankIndex;

      for (final char in rankText.split('')) {
        final emptyCount = int.tryParse(char);

        if (emptyCount != null) {
          fileIndex += emptyCount;
          continue;
        }

        if (fileIndex >= 8) {
          break;
        }

        final file = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
        pieces['$file$rankNumber'] = char;
        fileIndex += 1;
      }
    }

    return _FritzBoard(
      pieces: pieces,
      sideToMove: sidePart == 'b' ? _FritzColor.black : _FritzColor.white,
    );
  }

  final Map<String, String> pieces;
  final _FritzColor sideToMove;

  String? pieceAt(String square) {
    return pieces[square];
  }

  String? kingSquare(_FritzColor color) {
    final king = color == _FritzColor.white ? 'K' : 'k';

    for (final entry in pieces.entries) {
      if (entry.value == king) {
        return entry.key;
      }
    }

    return null;
  }

  _FritzBoard afterMove(String uciMove) {
    if (uciMove.length < 4) {
      return this;
    }

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length >= 5 ? uciMove.substring(4, 5) : '';

    final updatedPieces = Map<String, String>.from(pieces);
    final movingPiece = updatedPieces.remove(from);

    if (movingPiece == null) {
      return this;
    }

    var placedPiece = movingPiece;

    if (promotion.isNotEmpty && movingPiece.toLowerCase() == 'p') {
      placedPiece = movingPiece == movingPiece.toUpperCase()
          ? promotion.toUpperCase()
          : promotion.toLowerCase();
    }

    updatedPieces[to] = placedPiece;

    return _FritzBoard(
      pieces: updatedPieces,
      sideToMove: sideToMove.opposite,
    );
  }

  int materialBalanceFor(_FritzColor color) {
    var whiteMaterial = 0;
    var blackMaterial = 0;

    for (final piece in pieces.values) {
      final value = _pieceValue(piece.toLowerCase());

      if (piece == piece.toUpperCase()) {
        whiteMaterial += value;
      } else {
        blackMaterial += value;
      }
    }

    return color == _FritzColor.white
        ? whiteMaterial - blackMaterial
        : blackMaterial - whiteMaterial;
  }

  double get endgameFactor {
    var nonPawnMaterial = 0;

    for (final piece in pieces.values) {
      final type = piece.toLowerCase();

      if (type == 'k' || type == 'p') {
        continue;
      }

      nonPawnMaterial += _pieceValue(type);
    }

    return ((38 - nonPawnMaterial) / 26.0).clamp(0.0, 1.0).toDouble();
  }

  bool isKingAttacked(_FritzColor kingColor, {required _FritzColor by}) {
    final king = kingSquare(kingColor);

    if (king == null) {
      return false;
    }

    for (final entry in pieces.entries) {
      final piece = entry.value;
      final pieceColor = piece == piece.toUpperCase()
          ? _FritzColor.white
          : _FritzColor.black;

      if (pieceColor != by) {
        continue;
      }

      if (_pieceAttacksSquare(
        from: entry.key,
        pieceType: piece.toLowerCase(),
        target: king,
        color: by,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _pieceAttacksSquare({
    required String from,
    required String pieceType,
    required String target,
    required _FritzColor color,
  }) {
    final fromFile = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRank = int.parse(from.substring(1, 2));
    final targetFile = target.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final targetRank = int.parse(target.substring(1, 2));

    final df = targetFile - fromFile;
    final dr = targetRank - fromRank;
    final absDf = df.abs();
    final absDr = dr.abs();

    switch (pieceType) {
      case 'p':
        final direction = color == _FritzColor.white ? 1 : -1;
        return absDf == 1 && dr == direction;
      case 'n':
        return (absDf == 1 && absDr == 2) || (absDf == 2 && absDr == 1);
      case 'b':
        return absDf == absDr && _pathIsClear(from, target);
      case 'r':
        return (df == 0 || dr == 0) && _pathIsClear(from, target);
      case 'q':
        return ((absDf == absDr) || df == 0 || dr == 0) &&
            _pathIsClear(from, target);
      case 'k':
        return absDf <= 1 && absDr <= 1;
      default:
        return false;
    }
  }

  bool _pathIsClear(String from, String to) {
    final fromFile = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRank = int.parse(from.substring(1, 2));
    final toFile = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRank = int.parse(to.substring(1, 2));

    final df = (toFile - fromFile).sign;
    final dr = (toRank - fromRank).sign;

    var file = fromFile + df;
    var rank = fromRank + dr;

    while (file != toFile || rank != toRank) {
      final square = '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';

      if (pieces.containsKey(square)) {
        return false;
      }

      file += df;
      rank += dr;
    }

    return true;
  }

  static int _pieceValue(String pieceType) {
    switch (pieceType) {
      case 'p':
        return 1;
      case 'n':
      case 'b':
        return 3;
      case 'r':
        return 5;
      case 'q':
        return 9;
      default:
        return 0;
    }
  }
}

enum _FritzColor {
  white,
  black;

  _FritzColor get opposite {
    return this == _FritzColor.white ? _FritzColor.black : _FritzColor.white;
  }
}
