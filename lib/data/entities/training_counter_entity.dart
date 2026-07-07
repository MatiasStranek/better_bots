import 'package:objectbox/objectbox.dart';

@Entity()
class TrainingCounterEntity {
  TrainingCounterEntity({
    this.id = 0,
    required this.keyHash,
    required this.canonicalKey,
    required this.strengthModeName,
    required this.strengthValue,
    required this.effectiveOpeningName,
    required this.effectivePersonalityName,
    required this.personaCandidateCount,
    required this.cpLossUciSwitchFullMoveNumber,
    this.wonCount = 0,
    this.lostCount = 0,
    this.drawCount = 0,
    this.trainedCount = 0,
    this.wonWhiteCount = 0,
    this.wonBlackCount = 0,
    this.lostWhiteCount = 0,
    this.lostBlackCount = 0,
    this.drawWhiteCount = 0,
    this.drawBlackCount = 0,
    this.trainedWhiteCount = 0,
    this.trainedBlackCount = 0,
    this.createdAtMillis = 0,
    this.updatedAtMillis = 0,
  });

  int id;

  @Index()
  String keyHash;

  String canonicalKey;

  String strengthModeName;
  int strengthValue;
  String effectiveOpeningName;
  String effectivePersonalityName;
  int personaCandidateCount;

  /// Wird nur bei EngineStrengthMode.cpLossElo im Key berücksichtigt.
  /// Bei anderen Modi bleibt der Wert -1.
  int cpLossUciSwitchFullMoveNumber;

  int wonCount;
  int lostCount;
  int drawCount;
  int trainedCount;

  int wonWhiteCount;
  int wonBlackCount;
  int lostWhiteCount;
  int lostBlackCount;
  int drawWhiteCount;
  int drawBlackCount;
  int trainedWhiteCount;
  int trainedBlackCount;

  int createdAtMillis;
  int updatedAtMillis;
}
