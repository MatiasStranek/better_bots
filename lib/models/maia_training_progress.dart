import 'bot_opening_move.dart';
import 'bot_profile.dart';
import 'player_side.dart';

class MaiaSideCompletion {
  const MaiaSideCompletion({
    required this.white,
    required this.black,
  });

  const MaiaSideCompletion.none()
      : white = false,
        black = false;

  final bool white;
  final bool black;

  bool get both => white && black;
  bool get any => white || black;
}

class MaiaTrainingTarget {
  const MaiaTrainingTarget({
    required this.opening,
    required this.playerSide,
  });

  final BotOpeningMove opening;
  final PlayerSide playerSide;
}

class MaiaProfileTrainingProgress {
  const MaiaProfileTrainingProgress({
    required this.profile,
    required this.openingCompletions,
    required this.totalTrained,
    required this.trainedWhite,
    required this.trainedBlack,
  });

  final BotProfile profile;
  final Map<BotOpeningMove, MaiaSideCompletion> openingCompletions;
  final int totalTrained;
  final int trainedWhite;
  final int trainedBlack;

  MaiaSideCompletion completionFor(BotOpeningMove opening) {
    return openingCompletions[opening] ?? const MaiaSideCompletion.none();
  }

  MaiaSideCompletion completionForAll(Iterable<BotOpeningMove> openings) {
    final normalized = openings.toSet();

    if (normalized.isEmpty) {
      return const MaiaSideCompletion.none();
    }

    return MaiaSideCompletion(
      white: normalized.every((opening) => completionFor(opening).white),
      black: normalized.every((opening) => completionFor(opening).black),
    );
  }

  MaiaSideCompletion get openingsCompletion {
    return completionForAll(BotOpeningMove.realOpenings);
  }

  MaiaSideCompletion get allIdsCompletion {
    return completionForAll(BotOpeningMove.trainingOpenings);
  }

  List<MaiaTrainingTarget> get unwonTargets {
    final targets = <MaiaTrainingTarget>[];

    for (final opening in BotOpeningMove.trainingOpenings) {
      final completion = completionFor(opening);

      if (!completion.white) {
        targets.add(
          MaiaTrainingTarget(
            opening: opening,
            playerSide: PlayerSide.white,
          ),
        );
      }

      if (!completion.black) {
        targets.add(
          MaiaTrainingTarget(
            opening: opening,
            playerSide: PlayerSide.black,
          ),
        );
      }
    }

    return targets;
  }
}

class TrainingTotalsSnapshot {
  const TrainingTotalsSnapshot({
    required this.total,
    required this.white,
    required this.black,
  });

  const TrainingTotalsSnapshot.zero()
      : total = 0,
        white = 0,
        black = 0;

  final int total;
  final int white;
  final int black;
}

class MaiaTrainingSummary {
  const MaiaTrainingSummary({
    required this.profileProgress,
    required this.allTraining,
    required this.maiaTraining,
  });

  final Map<String, MaiaProfileTrainingProgress> profileProgress;
  final TrainingTotalsSnapshot allTraining;
  final TrainingTotalsSnapshot maiaTraining;

  MaiaProfileTrainingProgress forProfile(BotProfile profile) {
    return profileProgress[profile.id] ??
        MaiaProfileTrainingProgress(
          profile: profile,
          openingCompletions: const {},
          totalTrained: 0,
          trainedWhite: 0,
          trainedBlack: 0,
        );
  }
}
