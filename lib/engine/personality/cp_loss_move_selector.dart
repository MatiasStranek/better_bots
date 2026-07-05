import 'dart:math';

import 'cp_loss_elo_model.dart';
import 'persona_move_candidate.dart';

class CpLossMoveSelector {
  const CpLossMoveSelector();

  CpLossCandidatePool buildCandidatePool({
    required List<PersonaMoveCandidate> candidates,
    required int cpLossElo,
    Random? random,
  }) {
    final rng = random ?? Random();

    final validCandidates =
        candidates.where((candidate) => candidate.isValidMove).toList()
          ..sort((a, b) {
            final byMultiPv = a.multiPv.compareTo(b.multiPv);
            if (byMultiPv != 0) {
              return byMultiPv;
            }

            return b.scoreCp.compareTo(a.scoreCp);
          });

    final roll = CpLossEloModel.rollEffectiveTarget(
      selectedElo: cpLossElo,
      random: rng,
    );

    if (validCandidates.isEmpty) {
      return CpLossCandidatePool(
        roll: roll,
        bestCandidate: null,
        candidates: const [],
        candidateCount: 0,
        cappedCandidateCount: 0,
        eligibleCandidateCount: 0,
        scoredCandidates: const [],
      );
    }

    final bestCandidate = validCandidates.first;

    final scoredCandidates = validCandidates.map((candidate) {
      final rawLoss = candidate.centipawnLossComparedTo(bestCandidate);
      final safeLoss = max(0, rawLoss);

      return _CpLossScoredCandidate(candidate: candidate, cpLoss: safeLoss);
    }).toList();

    final cappedCandidates = _candidatesWithinMaxCpLoss(
      scoredCandidates: scoredCandidates,
      maxAllowedCpLoss: roll.maxAllowedCpLoss,
    );

    final eligibleCandidates = _eligibleCandidatesForRoll(
      roll: roll,
      cappedCandidates: cappedCandidates,
    );

    return CpLossCandidatePool(
      roll: roll,
      bestCandidate: bestCandidate,
      candidates: eligibleCandidates
          .map((scoredCandidate) => scoredCandidate.candidate)
          .toList(),
      candidateCount: validCandidates.length,
      cappedCandidateCount: cappedCandidates.length,
      eligibleCandidateCount: eligibleCandidates.length,
      scoredCandidates: eligibleCandidates,
    );
  }

  CpLossMoveSelection selectMove({
    required List<PersonaMoveCandidate> candidates,
    required int cpLossElo,
    Random? random,
  }) {
    final rng = random ?? Random();

    final pool = buildCandidatePool(
      candidates: candidates,
      cpLossElo: cpLossElo,
      random: rng,
    );

    return selectMoveFromPool(pool: pool, random: rng);
  }

  CpLossMoveSelection selectMoveFromPool({
    required CpLossCandidatePool pool,
    Random? random,
  }) {
    final rng = random ?? Random();
    final roll = pool.roll;

    if (pool._scoredCandidates.isEmpty) {
      return CpLossMoveSelection(
        uciMove: '(none)',
        selectedElo: roll.selectedElo,
        originalEffectiveElo: roll.originalEffectiveElo,
        effectiveElo: roll.effectiveElo,
        targetCpLoss: roll.targetCpLoss,
        maxAllowedCpLoss: roll.maxAllowedCpLoss,
        phase: roll.phase,
        offset: roll.offset,
        wasLimitedByMaxCpLoss: roll.wasLimitedByMaxCpLoss,
        chosenCpLoss: 0,
        candidateCount: pool.candidateCount,
        eligibleCandidateCount: pool.eligibleCandidateCount,
        cappedCandidateCount: pool.cappedCandidateCount,
      );
    }

    final chosen = _nearestCandidateToTarget(
      candidates: pool._scoredCandidates,
      targetCpLoss: roll.targetCpLoss,
      random: rng,
    );

    return CpLossMoveSelection(
      uciMove: chosen.candidate.uciMove,
      selectedElo: roll.selectedElo,
      originalEffectiveElo: roll.originalEffectiveElo,
      effectiveElo: roll.effectiveElo,
      targetCpLoss: roll.targetCpLoss,
      maxAllowedCpLoss: roll.maxAllowedCpLoss,
      phase: roll.phase,
      offset: roll.offset,
      wasLimitedByMaxCpLoss: roll.wasLimitedByMaxCpLoss,
      chosenCpLoss: chosen.cpLoss,
      candidateCount: pool.candidateCount,
      eligibleCandidateCount: pool.eligibleCandidateCount,
      cappedCandidateCount: pool.cappedCandidateCount,
    );
  }

  int cpLossForMoveInPool({
    required CpLossCandidatePool pool,
    required String uciMove,
  }) {
    for (final scoredCandidate in pool._scoredCandidates) {
      if (scoredCandidate.candidate.uciMove == uciMove) {
        return scoredCandidate.cpLoss;
      }
    }

    return 0;
  }

  List<_CpLossScoredCandidate> _candidatesWithinMaxCpLoss({
    required List<_CpLossScoredCandidate> scoredCandidates,
    required int maxAllowedCpLoss,
  }) {
    if (scoredCandidates.length <= 1) {
      return scoredCandidates;
    }

    if (maxAllowedCpLoss >= 100000) {
      return scoredCandidates;
    }

    final cappedCandidates = scoredCandidates.where((candidate) {
      return candidate.cpLoss <= maxAllowedCpLoss;
    }).toList();

    if (cappedCandidates.isNotEmpty) {
      return cappedCandidates;
    }

    final bestCandidate = scoredCandidates.reduce((a, b) {
      return a.cpLoss <= b.cpLoss ? a : b;
    });

    return [bestCandidate];
  }

  List<_CpLossScoredCandidate> _eligibleCandidatesForRoll({
    required CpLossEloRollResult roll,
    required List<_CpLossScoredCandidate> cappedCandidates,
  }) {
    if (cappedCandidates.length <= 1) {
      return cappedCandidates;
    }

    switch (roll.phase) {
      case CpLossEloPhase.target:
        return _targetPhaseCandidates(
          targetCpLoss: roll.targetCpLoss,
          cappedCandidates: cappedCandidates,
        );

      case CpLossEloPhase.underAverage:
        final underCandidates = cappedCandidates.where((candidate) {
          return candidate.cpLoss >= roll.targetCpLoss;
        }).toList();

        if (underCandidates.isNotEmpty) {
          return underCandidates;
        }

        return cappedCandidates;

      case CpLossEloPhase.overAverage:
        final overCandidates = cappedCandidates.where((candidate) {
          return candidate.cpLoss <= roll.targetCpLoss;
        }).toList();

        if (overCandidates.isNotEmpty) {
          return overCandidates;
        }

        return cappedCandidates;
    }
  }

  List<_CpLossScoredCandidate> _targetPhaseCandidates({
    required int targetCpLoss,
    required List<_CpLossScoredCandidate> cappedCandidates,
  }) {
    if (cappedCandidates.length <= 1) {
      return cappedCandidates;
    }

    final nearestDistance = cappedCandidates
        .map((candidate) => (candidate.cpLoss - targetCpLoss).abs())
        .reduce(min);

    final tolerance = _targetPhaseTolerance(targetCpLoss);

    var targetCandidates = cappedCandidates.where((candidate) {
      final distance = (candidate.cpLoss - targetCpLoss).abs();
      return distance <= nearestDistance + tolerance;
    }).toList();

    if (targetCandidates.isNotEmpty) {
      return targetCandidates;
    }

    targetCandidates = cappedCandidates.where((candidate) {
      final distance = (candidate.cpLoss - targetCpLoss).abs();
      return distance == nearestDistance;
    }).toList();

    if (targetCandidates.isNotEmpty) {
      return targetCandidates;
    }

    return cappedCandidates;
  }

  int _targetPhaseTolerance(int targetCpLoss) {
    if (targetCpLoss <= 0) {
      return 2;
    }

    if (targetCpLoss <= 10) {
      return 6;
    }

    if (targetCpLoss <= 30) {
      return 10;
    }

    if (targetCpLoss <= 80) {
      return 18;
    }

    if (targetCpLoss <= 150) {
      return 28;
    }

    return 40;
  }

  _CpLossScoredCandidate _nearestCandidateToTarget({
    required List<_CpLossScoredCandidate> candidates,
    required int targetCpLoss,
    required Random random,
  }) {
    if (candidates.isEmpty) {
      throw StateError('Es wurden keine CP-Loss-Kandidaten übergeben.');
    }

    final sortedCandidates = List<_CpLossScoredCandidate>.from(candidates)
      ..sort((a, b) {
        final aDistance = (a.cpLoss - targetCpLoss).abs();
        final bDistance = (b.cpLoss - targetCpLoss).abs();

        final byDistance = aDistance.compareTo(bDistance);
        if (byDistance != 0) {
          return byDistance;
        }

        final byWorseMove = b.cpLoss.compareTo(a.cpLoss);
        if (byWorseMove != 0) {
          return byWorseMove;
        }

        return a.candidate.multiPv.compareTo(b.candidate.multiPv);
      });

    final bestDistance = (sortedCandidates.first.cpLoss - targetCpLoss).abs();

    final equallyCloseCandidates = sortedCandidates.where((candidate) {
      return (candidate.cpLoss - targetCpLoss).abs() == bestDistance;
    }).toList();

    final worstEquallyCloseLoss = equallyCloseCandidates
        .map((candidate) => candidate.cpLoss)
        .reduce(max);

    final tieWinners =
        equallyCloseCandidates.where((candidate) {
            return candidate.cpLoss == worstEquallyCloseLoss;
          }).toList()
          ..sort((a, b) => a.candidate.multiPv.compareTo(b.candidate.multiPv));

    if (tieWinners.length == 1) {
      return tieWinners.first;
    }

    return tieWinners[random.nextInt(tieWinners.length)];
  }
}

class CpLossCandidatePool {
  const CpLossCandidatePool({
    required this.roll,
    required this.bestCandidate,
    required this.candidates,
    required this.candidateCount,
    required this.cappedCandidateCount,
    required this.eligibleCandidateCount,
    required List<_CpLossScoredCandidate> scoredCandidates,
  }) : _scoredCandidates = scoredCandidates;

  final CpLossEloRollResult roll;
  final PersonaMoveCandidate? bestCandidate;

  /// Der finale Qualitätskorridor.
  ///
  /// Persönlichkeiten dürfen ausschließlich aus dieser Liste wählen.
  /// Max_CP_Loss wurde hier bereits hart angewendet.
  final List<PersonaMoveCandidate> candidates;

  final int candidateCount;
  final int cappedCandidateCount;
  final int eligibleCandidateCount;

  final List<_CpLossScoredCandidate> _scoredCandidates;

  bool get isEmpty => candidates.isEmpty;

  String get debugPrefix {
    final offsetText = roll.offset == 0 ? '' : ' | Offset: ${roll.offset} ELO';

    final limitedText = roll.wasLimitedByMaxCpLoss
        ? ' | Max-Loss begrenzt: '
              '${roll.originalEffectiveElo} → ${roll.effectiveElo}'
        : '';

    final maxLossText = roll.maxAllowedCpLoss >= 100000
        ? 'frei'
        : '${roll.maxAllowedCpLoss} cp';

    return 'CP_Loss_ELO: ${roll.selectedElo} | '
        'Phase: ${roll.phase.label}$offsetText | '
        'Effektiv: ${roll.effectiveElo} | '
        'Ziel-Loss: ${roll.targetCpLoss} cp | '
        'Max-Loss: $maxLossText | '
        'Kandidaten: $eligibleCandidateCount/$cappedCandidateCount/$candidateCount'
        '$limitedText';
  }
}

class CpLossMoveSelection {
  const CpLossMoveSelection({
    required this.uciMove,
    required this.selectedElo,
    required this.originalEffectiveElo,
    required this.effectiveElo,
    required this.targetCpLoss,
    required this.maxAllowedCpLoss,
    required this.phase,
    required this.offset,
    required this.wasLimitedByMaxCpLoss,
    required this.chosenCpLoss,
    required this.candidateCount,
    required this.eligibleCandidateCount,
    required this.cappedCandidateCount,
  });

  final String uciMove;
  final int selectedElo;
  final int originalEffectiveElo;
  final int effectiveElo;
  final int targetCpLoss;
  final int maxAllowedCpLoss;
  final CpLossEloPhase phase;
  final int offset;
  final bool wasLimitedByMaxCpLoss;
  final int chosenCpLoss;
  final int candidateCount;
  final int eligibleCandidateCount;
  final int cappedCandidateCount;

  String get debugText {
    final offsetText = offset == 0 ? '' : ' | Offset: ${offset} ELO';

    final limitedText = wasLimitedByMaxCpLoss
        ? ' | Max-Loss begrenzt: $originalEffectiveElo → $effectiveElo'
        : '';

    final maxLossText = maxAllowedCpLoss >= 100000
        ? 'frei'
        : '$maxAllowedCpLoss cp';

    return 'CP_Loss_ELO: $selectedElo | '
        'Phase: ${phase.label}$offsetText | '
        'Effektiv: $effectiveElo | '
        'Ziel-Loss: $targetCpLoss cp | '
        'Max-Loss: $maxLossText | '
        'Gewählt: $chosenCpLoss cp | '
        'Kandidaten: $eligibleCandidateCount/$cappedCandidateCount/$candidateCount | '
        'Zug: $uciMove'
        '$limitedText';
  }
}

class _CpLossScoredCandidate {
  const _CpLossScoredCandidate({required this.candidate, required this.cpLoss});

  final PersonaMoveCandidate candidate;
  final int cpLoss;
}
