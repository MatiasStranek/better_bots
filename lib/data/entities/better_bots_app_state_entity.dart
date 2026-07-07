import 'package:objectbox/objectbox.dart';

@Entity()
class AppStateEntity {
  AppStateEntity({
    this.id = 0,
    this.playerSideName = 'white',
    this.skillLevel = 0,
    this.strengthModeName = 'cpLossElo',
    this.uciElo = 1320,
    this.cpLossElo = 1600,
    this.cpLossUciSwitchFullMoveNumber = 11,
    this.botOpeningMoveName = 'random',
    this.effectiveBotOpeningMoveName = 'none',
    this.selectedOpeningMoveNames = '',
    this.personalitySourceName = 'chessiverse',
    this.effectivePersonalitySourceName = 'chessiverse',
    this.botPersonalityName = 'random',
    this.effectiveBotPersonalityName = 'none',
    this.fritz19PersonalityName = 'allrounder',
    this.effectiveFritz19PersonalityName = 'allrounder',
    this.selectedChessiversePersonalityNames = '',
    this.selectedFritz19PersonalityNames = '',
    this.personaCandidateCount = 64,
    this.openingLogicAllowed = 1,
    this.startFen = '',
    this.moveListText = '',
    this.currentFen = '',
    this.lastFrom = '',
    this.lastTo = '',
    this.analysisUsedDuringCurrentGame = 0,
    this.resultCountedForCurrentGame = 0,
    this.updatedAtMillis = 0,
  });

  int id;

  String playerSideName;

  int skillLevel;
  String strengthModeName;
  int uciElo;
  int cpLossElo;
  int cpLossUciSwitchFullMoveNumber;

  String botOpeningMoveName;
  String effectiveBotOpeningMoveName;
  String selectedOpeningMoveNames;

  String personalitySourceName;
  String effectivePersonalitySourceName;
  String botPersonalityName;
  String effectiveBotPersonalityName;
  String fritz19PersonalityName;
  String effectiveFritz19PersonalityName;
  String selectedChessiversePersonalityNames;
  String selectedFritz19PersonalityNames;

  int personaCandidateCount;
  int openingLogicAllowed;

  String startFen;
  String moveListText;
  String currentFen;
  String lastFrom;
  String lastTo;

  int analysisUsedDuringCurrentGame;
  int resultCountedForCurrentGame;

  int updatedAtMillis;
}
