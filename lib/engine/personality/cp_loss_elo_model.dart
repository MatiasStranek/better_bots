import 'dart:math';

class CpLossEloModel {
  const CpLossEloModel._();

  static const int minElo = 0;
  static const int maxElo = 4000;
  static const int perfectCpLossElo = 3100;

  static const Map<int, int> cpLossByElo = {
    0: 573,
    100: 343,
    200: 274,
    300: 234,
    400: 205,
    500: 183,
    600: 164,
    700: 149,
    800: 136,
    900: 124,
    1000: 113,
    1100: 104,
    1200: 95,
    1300: 87,
    1400: 79,
    1500: 73,
    1600: 66,
    1700: 60,
    1800: 54,
    1900: 49,
    2000: 44,
    2100: 39,
    2200: 34,
    2300: 30,
    2400: 26,
    2500: 22,
    2600: 18,
    2700: 14,
    2800: 10,
    2900: 7,
    3000: 3,
    3100: 0,
    3200: 0,
    3300: 0,
    3400: 0,
    3500: 0,
    3600: 0,
    3700: 0,
    3800: 0,
    3900: 0,
    4000: 0,
  };

  static const Map<int, int> maxAllowedCpLossByElo = {
    0: 1000,
    100: 900,
    200: 800,
    300: 700,
    400: 620,
    500: 550,
    600: 490,
    700: 440,
    800: 390,
    900: 350,
    1000: 315,
    1100: 290,
    1200: 275,
    1300: 260,
    1400: 230,
    1500: 205,
    1600: 180,
    1700: 160,
    1800: 140,
    1900: 125,
    2000: 110,
    2100: 95,
    2200: 85,
    2300: 75,
    2400: 65,
    2500: 55,
    2600: 45,
    2700: 36,
    2800: 28,
    2900: 20,
    3000: 12,
    3100: 15,
    3200: 10,
    3300: 10,
    3400: 10,
    3500: 10,
    3600: 10,
    3700: 10,
    3800: 10,
    3900: 10,
    4000: 0,
  };

  static const Map<int, double> targetChanceByEloFrom3100 = {
    3100: 0.85,
    3200: 0.87,
    3300: 0.89,
    3400: 0.91,
    3500: 0.93,
    3600: 0.95,
    3700: 0.965,
    3800: 0.98,
    3900: 0.99,
    4000: 1.00,
  };

  static const List<CpLossEloOffsetChance> offsetChances = [
    CpLossEloOffsetChance(offset: 100, chance: 0.40),
    CpLossEloOffsetChance(offset: 200, chance: 0.25),
    CpLossEloOffsetChance(offset: 300, chance: 0.17),
    CpLossEloOffsetChance(offset: 400, chance: 0.11),
    CpLossEloOffsetChance(offset: 500, chance: 0.07),
  ];

  static int normalizeElo(int elo) {
    final rounded = (elo / 100).round() * 100;
    return rounded.clamp(minElo, maxElo).toInt();
  }

  static int cpLossForElo(int elo) {
    final normalized = normalizeElo(elo);
    return cpLossByElo[normalized] ?? 0;
  }

  static int maxAllowedCpLossForElo(int elo) {
    final normalized = normalizeElo(elo);
    return maxAllowedCpLossByElo[normalized] ?? 10;
  }

  static bool cpLossFitsMaxAllowed({
    required int selectedElo,
    required int cpLoss,
  }) {
    return cpLoss <= maxAllowedCpLossForElo(selectedElo);
  }

  static double targetChanceForElo(int elo) {
    final normalized = normalizeElo(elo);

    if (normalized < perfectCpLossElo) {
      return 0.80;
    }

    return targetChanceByEloFrom3100[normalized] ?? 1.0;
  }

  static CpLossEloRollResult rollEffectiveTarget({
    required int selectedElo,
    Random? random,
  }) {
    final rng = random ?? Random();
    final normalizedSelectedElo = normalizeElo(selectedElo);
    final targetChance = targetChanceForElo(normalizedSelectedElo);
    final maxAllowedCpLoss = maxAllowedCpLossForElo(normalizedSelectedElo);

    final roll = rng.nextDouble();

    if (roll < targetChance) {
      return CpLossEloRollResult(
        selectedElo: normalizedSelectedElo,
        originalEffectiveElo: normalizedSelectedElo,
        effectiveElo: normalizedSelectedElo,
        targetCpLoss: cpLossForElo(normalizedSelectedElo),
        maxAllowedCpLoss: maxAllowedCpLoss,
        phase: CpLossEloPhase.target,
        phaseChance: targetChance,
        offset: 0,
        wasLimitedByMaxCpLoss: false,
      );
    }

    final offset = _rollOffset(rng);

    if (normalizedSelectedElo >= perfectCpLossElo) {
      final originalEffectiveElo = (perfectCpLossElo - offset)
          .clamp(minElo, perfectCpLossElo)
          .toInt();

      final effectiveElo = _limitUnderAverageEloByMaxCpLoss(
        selectedElo: normalizedSelectedElo,
        originalEffectiveElo: originalEffectiveElo,
      );

      return CpLossEloRollResult(
        selectedElo: normalizedSelectedElo,
        originalEffectiveElo: originalEffectiveElo,
        effectiveElo: effectiveElo,
        targetCpLoss: cpLossForElo(effectiveElo),
        maxAllowedCpLoss: maxAllowedCpLoss,
        phase: CpLossEloPhase.underAverage,
        phaseChance: 1.0 - targetChance,
        offset: offset,
        wasLimitedByMaxCpLoss: effectiveElo != originalEffectiveElo,
      );
    }

    final remainingChance = 1.0 - targetChance;

    const underShare = 0.75;
    final underChance = remainingChance * underShare;

    final isUnderAverage = roll < targetChance + underChance;

    final originalEffectiveElo = normalizeElo(
      isUnderAverage
          ? normalizedSelectedElo - offset
          : normalizedSelectedElo + offset,
    );

    final effectiveElo = isUnderAverage
        ? _limitUnderAverageEloByMaxCpLoss(
            selectedElo: normalizedSelectedElo,
            originalEffectiveElo: originalEffectiveElo,
          )
        : originalEffectiveElo;

    return CpLossEloRollResult(
      selectedElo: normalizedSelectedElo,
      originalEffectiveElo: originalEffectiveElo,
      effectiveElo: effectiveElo,
      targetCpLoss: cpLossForElo(effectiveElo),
      maxAllowedCpLoss: maxAllowedCpLoss,
      phase: isUnderAverage
          ? CpLossEloPhase.underAverage
          : CpLossEloPhase.overAverage,
      phaseChance: isUnderAverage ? 0.15 : 0.05,
      offset: offset,
      wasLimitedByMaxCpLoss:
          isUnderAverage && effectiveElo != originalEffectiveElo,
    );
  }

  static int _limitUnderAverageEloByMaxCpLoss({
    required int selectedElo,
    required int originalEffectiveElo,
  }) {
    final normalizedSelectedElo = normalizeElo(selectedElo);
    final maxAllowedCpLoss = maxAllowedCpLossForElo(normalizedSelectedElo);

    var candidateElo = normalizeElo(originalEffectiveElo);

    while (candidateElo < normalizedSelectedElo) {
      final candidateCpLoss = cpLossForElo(candidateElo);

      if (candidateCpLoss <= maxAllowedCpLoss) {
        return candidateElo;
      }

      candidateElo = normalizeElo(candidateElo + 100);
    }

    return normalizedSelectedElo;
  }

  static int _rollOffset(Random random) {
    final roll = random.nextDouble();
    var cumulativeChance = 0.0;

    for (final offsetChance in offsetChances) {
      cumulativeChance += offsetChance.chance;

      if (roll < cumulativeChance) {
        return offsetChance.offset;
      }
    }

    return offsetChances.last.offset;
  }
}

enum CpLossEloPhase {
  target(label: 'ELO-gerecht'),
  underAverage(label: 'Unter_Durchschnitt'),
  overAverage(label: 'Über_Durchschnitt');

  const CpLossEloPhase({required this.label});

  final String label;
}

class CpLossEloOffsetChance {
  const CpLossEloOffsetChance({required this.offset, required this.chance});

  final int offset;
  final double chance;
}

class CpLossEloRollResult {
  const CpLossEloRollResult({
    required this.selectedElo,
    required this.originalEffectiveElo,
    required this.effectiveElo,
    required this.targetCpLoss,
    required this.maxAllowedCpLoss,
    required this.phase,
    required this.phaseChance,
    required this.offset,
    required this.wasLimitedByMaxCpLoss,
  });

  final int selectedElo;
  final int originalEffectiveElo;
  final int effectiveElo;
  final int targetCpLoss;
  final int maxAllowedCpLoss;
  final CpLossEloPhase phase;
  final double phaseChance;
  final int offset;
  final bool wasLimitedByMaxCpLoss;

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
        'Max-Loss: $maxLossText'
        '$limitedText';
  }
}
