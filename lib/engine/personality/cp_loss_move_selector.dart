import 'dart:math';

import 'cp_loss_elo_model.dart';
import 'persona_move_candidate.dart';

class CpLossMoveSelector {
  const CpLossMoveSelector();

  CpLossMoveSelection selectMove({
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
        candidateCount: 0,
        eligibleCandidateCount: 0,
        cappedCandidateCount: 0,
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

    final chosen = _nearestCandidateToTarget(
      candidates: eligibleCandidates,
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
      candidateCount: validCandidates.length,
      eligibleCandidateCount: eligibleCandidates.length,
      cappedCandidateCount: cappedCandidates.length,
    );
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

    return scoredCandidates;
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
        return cappedCandidates;

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
