import 'dart:math' as math;

import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/bot_opening_move.dart';
import '../models/bot_personality.dart';
import '../models/engine_strength_mode.dart';
import '../models/player_side.dart';
import '../objectbox.g.dart';
import 'entities/better_bots_app_state_entity.dart';
import 'entities/training_counter_entity.dart';

enum TrainingCounterIncrement { won, lost, draw, trained }

class TrainingCounterSnapshot {
  const TrainingCounterSnapshot({
    required this.keyHash,
    required this.wonCount,
    required this.lostCount,
    required this.drawCount,
    required this.trainedCount,
    required this.wonWhiteCount,
    required this.wonBlackCount,
    required this.lostWhiteCount,
    required this.lostBlackCount,
    required this.drawWhiteCount,
    required this.drawBlackCount,
    required this.trainedWhiteCount,
    required this.trainedBlackCount,
  });

  const TrainingCounterSnapshot.zero()
      : keyHash = '',
        wonCount = 0,
        lostCount = 0,
        drawCount = 0,
        trainedCount = 0,
        wonWhiteCount = 0,
        wonBlackCount = 0,
        lostWhiteCount = 0,
        lostBlackCount = 0,
        drawWhiteCount = 0,
        drawBlackCount = 0,
        trainedWhiteCount = 0,
        trainedBlackCount = 0;

  final String keyHash;
  final int wonCount;
  final int lostCount;
  final int drawCount;
  final int trainedCount;

  final int wonWhiteCount;
  final int wonBlackCount;
  final int lostWhiteCount;
  final int lostBlackCount;
  final int drawWhiteCount;
  final int drawBlackCount;
  final int trainedWhiteCount;
  final int trainedBlackCount;
}

class TrainingCounterKey {
  const TrainingCounterKey({
    required this.keyHash,
    required this.canonicalKey,
    required this.strengthModeName,
    required this.strengthValue,
    required this.effectiveOpeningName,
    required this.personalitySourceName,
    required this.effectivePersonalityName,
    required this.personaCandidateCount,
    required this.cpLossUciSwitchFullMoveNumber,
  });

  final String keyHash;
  final String canonicalKey;
  final String strengthModeName;
  final int strengthValue;
  final String effectiveOpeningName;
  final String personalitySourceName;
  final String effectivePersonalityName;
  final int personaCandidateCount;
  final int cpLossUciSwitchFullMoveNumber;
}

class BetterBotsDatabase {
  BetterBotsDatabase._();

  static final BetterBotsDatabase instance = BetterBotsDatabase._();

  Store? _store;
  Box<AppStateEntity>? _appStateBox;
  Box<TrainingCounterEntity>? _trainingCounterBox;

  bool get isReady => _store != null;

  Future<void> init() async {
    if (_store != null) {
      return;
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = p.join(
      supportDirectory.path,
      'better_bots_objectbox',
    );

    final store = await openStore(directory: databaseDirectory);

    _store = store;
    _appStateBox = store.box<AppStateEntity>();
    _trainingCounterBox = store.box<TrainingCounterEntity>();
  }

  AppStateEntity? loadAppState() {
    final box = _appStateBox;

    if (box == null) {
      return null;
    }

    final states = box.getAll();

    if (states.isEmpty) {
      return null;
    }

    return states.first;
  }

  void saveAppState(AppStateEntity state) {
    final box = _appStateBox;

    if (box == null) {
      return;
    }

    final existingState = loadAppState();

    state
      ..id = existingState?.id ?? 0
      ..updatedAtMillis = DateTime.now().millisecondsSinceEpoch;

    box.put(state);
  }

  TrainingCounterSnapshot counterSnapshotFor({
    required EngineStrengthMode strengthMode,
    required int skillLevel,
    required int uciElo,
    required int cpLossElo,
    required int cpLossUciSwitchFullMoveNumber,
    required BotOpeningMove effectiveOpeningMove,
    required String personalitySourceName,
    required String effectivePersonalityName,
    required int personaCandidateCount,
  }) {
    final key = buildTrainingCounterKey(
      strengthMode: strengthMode,
      skillLevel: skillLevel,
      uciElo: uciElo,
      cpLossElo: cpLossElo,
      cpLossUciSwitchFullMoveNumber: cpLossUciSwitchFullMoveNumber,
      effectiveOpeningMove: effectiveOpeningMove,
      personalitySourceName: personalitySourceName,
      effectivePersonalityName: effectivePersonalityName,
      personaCandidateCount: personaCandidateCount,
    );

    final entity = _findCounterByHash(key.keyHash);

    if (entity == null) {
      return TrainingCounterSnapshot(
        keyHash: key.keyHash,
        wonCount: 0,
        lostCount: 0,
        drawCount: 0,
        trainedCount: 0,
        wonWhiteCount: 0,
        wonBlackCount: 0,
        lostWhiteCount: 0,
        lostBlackCount: 0,
        drawWhiteCount: 0,
        drawBlackCount: 0,
        trainedWhiteCount: 0,
        trainedBlackCount: 0,
      );
    }

    return TrainingCounterSnapshot(
      keyHash: entity.keyHash,
      wonCount: entity.wonCount,
      lostCount: entity.lostCount,
      drawCount: entity.drawCount,
      trainedCount: entity.trainedCount,
      wonWhiteCount: entity.wonWhiteCount,
      wonBlackCount: entity.wonBlackCount,
      lostWhiteCount: entity.lostWhiteCount,
      lostBlackCount: entity.lostBlackCount,
      drawWhiteCount: entity.drawWhiteCount,
      drawBlackCount: entity.drawBlackCount,
      trainedWhiteCount: entity.trainedWhiteCount,
      trainedBlackCount: entity.trainedBlackCount,
    );
  }

  TrainingCounterSnapshot incrementCounter({
    required TrainingCounterIncrement increment,
    required PlayerSide playerSide,
    required EngineStrengthMode strengthMode,
    required int skillLevel,
    required int uciElo,
    required int cpLossElo,
    required int cpLossUciSwitchFullMoveNumber,
    required BotOpeningMove effectiveOpeningMove,
    required String personalitySourceName,
    required String effectivePersonalityName,
    required int personaCandidateCount,
  }) {
    final box = _trainingCounterBox;

    final key = buildTrainingCounterKey(
      strengthMode: strengthMode,
      skillLevel: skillLevel,
      uciElo: uciElo,
      cpLossElo: cpLossElo,
      cpLossUciSwitchFullMoveNumber: cpLossUciSwitchFullMoveNumber,
      effectiveOpeningMove: effectiveOpeningMove,
      personalitySourceName: personalitySourceName,
      effectivePersonalityName: effectivePersonalityName,
      personaCandidateCount: personaCandidateCount,
    );

    if (box == null) {
      return const TrainingCounterSnapshot.zero();
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final entity = _findCounterByHash(key.keyHash) ??
        TrainingCounterEntity(
          keyHash: key.keyHash,
          canonicalKey: key.canonicalKey,
          strengthModeName: key.strengthModeName,
          strengthValue: key.strengthValue,
          effectiveOpeningName: key.effectiveOpeningName,
          personalitySourceName: key.personalitySourceName,
          effectivePersonalityName: key.effectivePersonalityName,
          personaCandidateCount: key.personaCandidateCount,
          cpLossUciSwitchFullMoveNumber: key.cpLossUciSwitchFullMoveNumber,
          createdAtMillis: now,
        );

    switch (increment) {
      case TrainingCounterIncrement.won:
        entity.wonCount += 1;
        if (playerSide == PlayerSide.white) {
          entity.wonWhiteCount += 1;
        } else {
          entity.wonBlackCount += 1;
        }
      case TrainingCounterIncrement.lost:
        entity.lostCount += 1;
        if (playerSide == PlayerSide.white) {
          entity.lostWhiteCount += 1;
        } else {
          entity.lostBlackCount += 1;
        }
      case TrainingCounterIncrement.draw:
        entity.drawCount += 1;
        if (playerSide == PlayerSide.white) {
          entity.drawWhiteCount += 1;
        } else {
          entity.drawBlackCount += 1;
        }
      case TrainingCounterIncrement.trained:
        entity.trainedCount += 1;
        if (playerSide == PlayerSide.white) {
          entity.trainedWhiteCount += 1;
        } else {
          entity.trainedBlackCount += 1;
        }
    }

    entity
      ..canonicalKey = key.canonicalKey
      ..strengthModeName = key.strengthModeName
      ..strengthValue = key.strengthValue
      ..effectiveOpeningName = key.effectiveOpeningName
      ..personalitySourceName = key.personalitySourceName
      ..effectivePersonalityName = key.effectivePersonalityName
      ..personaCandidateCount = key.personaCandidateCount
      ..cpLossUciSwitchFullMoveNumber = key.cpLossUciSwitchFullMoveNumber
      ..updatedAtMillis = now;

    box.put(entity);

    return TrainingCounterSnapshot(
      keyHash: entity.keyHash,
      wonCount: entity.wonCount,
      lostCount: entity.lostCount,
      drawCount: entity.drawCount,
      trainedCount: entity.trainedCount,
      wonWhiteCount: entity.wonWhiteCount,
      wonBlackCount: entity.wonBlackCount,
      lostWhiteCount: entity.lostWhiteCount,
      lostBlackCount: entity.lostBlackCount,
      drawWhiteCount: entity.drawWhiteCount,
      drawBlackCount: entity.drawBlackCount,
      trainedWhiteCount: entity.trainedWhiteCount,
      trainedBlackCount: entity.trainedBlackCount,
    );
  }

  TrainingCounterKey buildTrainingCounterKey({
    required EngineStrengthMode strengthMode,
    required int skillLevel,
    required int uciElo,
    required int cpLossElo,
    required int cpLossUciSwitchFullMoveNumber,
    required BotOpeningMove effectiveOpeningMove,
    required String personalitySourceName,
    required String effectivePersonalityName,
    required int personaCandidateCount,
  }) {
    final strengthValue = switch (strengthMode) {
      EngineStrengthMode.level => skillLevel,
      EngineStrengthMode.uciElo => uciElo,
      EngineStrengthMode.cpLossElo => cpLossElo,
    };

    final normalizedCandidateCount = math.max(1, personaCandidateCount);
    final normalizedSwitch = strengthMode == EngineStrengthMode.cpLossElo
        ? cpLossUciSwitchFullMoveNumber
        : -1;

    final parts = <String>[
      'mode=${strengthMode.name}',
      'strength=$strengthValue',
      'opening=${effectiveOpeningMove.name}',
      'personalitySource=$personalitySourceName',
      'personality=$effectivePersonalityName',
      'candidates=$normalizedCandidateCount',
      if (strengthMode == EngineStrengthMode.cpLossElo)
        'uciSwitch=$normalizedSwitch',
    ];

    final canonicalKey = parts.join('|');

    return TrainingCounterKey(
      keyHash: _fnv1a64Hex(canonicalKey),
      canonicalKey: canonicalKey,
      strengthModeName: strengthMode.name,
      strengthValue: strengthValue,
      effectiveOpeningName: effectiveOpeningMove.name,
      personalitySourceName: personalitySourceName,
      effectivePersonalityName: effectivePersonalityName,
      personaCandidateCount: normalizedCandidateCount,
      cpLossUciSwitchFullMoveNumber: normalizedSwitch,
    );
  }

  TrainingCounterEntity? _findCounterByHash(String keyHash) {
    final box = _trainingCounterBox;

    if (box == null) {
      return null;
    }

    for (final entity in box.getAll()) {
      if (entity.keyHash == keyHash) {
        return entity;
      }
    }

    return null;
  }

  String _fnv1a64Hex(String input) {
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final codeUnit in input.codeUnits) {
      hash ^= BigInt.from(codeUnit);
      hash = (hash * prime) & mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
