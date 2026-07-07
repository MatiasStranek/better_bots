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
    this.botPersonalityName = 'random',
    this.effectiveBotPersonalityName = 'none',
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

  String botPersonalityName;
  String effectiveBotPersonalityName;

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
