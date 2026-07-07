import 'package:flutter/material.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_personality.dart';
import '../../../models/bot_personality_source.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/fritz19_personality.dart';

class MobileChessGameInfoPanel extends StatelessWidget {
  const MobileChessGameInfoPanel({
    super.key,
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.effectiveBotOpeningMove,
    required this.botPersonalitySource,
    required this.effectiveBotPersonalitySource,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.fritz19Personality,
    required this.effectiveFritz19Personality,
    required this.personaCandidateCount,
  });

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final int cpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotOpeningMove effectiveBotOpeningMove;
  final BotPersonalitySource botPersonalitySource;
  final BotPersonalitySource effectiveBotPersonalitySource;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final Fritz19Personality fritz19Personality;
  final Fritz19Personality effectiveFritz19Personality;
  final int personaCandidateCount;

  String get _strengthText {
    switch (strengthMode) {
      case EngineStrengthMode.level:
        return 'Level $skillLevel';
      case EngineStrengthMode.uciElo:
        return 'UCI $uciElo';
      case EngineStrengthMode.cpLossElo:
        return 'CP $cpLossElo';
    }
  }

  String get _openingText {
    if (botOpeningMove == BotOpeningMove.random) {
      return 'Zufällig: ${effectiveBotOpeningMove.label}';
    }

    return botOpeningMove.label;
  }

  String get _personalityText {
    if (botPersonalitySource == BotPersonalitySource.random) {
      if (effectiveBotPersonalitySource == BotPersonalitySource.fritz19) {
        return 'Alles Zufällig: Fritz19 '
            '${effectiveFritz19Personality.label}';
      }

      return 'Alles Zufällig: ${effectiveBotPersonality.label}';
    }

    if (botPersonalitySource == BotPersonalitySource.fritz19) {
      if (fritz19Personality == Fritz19Personality.random) {
        return 'Fritz19 Zufällig: ${effectiveFritz19Personality.label}';
      }

      return 'Fritz19: ${fritz19Personality.label}';
    }

    if (botPersonality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      return 'Zufällig: ${effectiveBotPersonality.label}';
    }

    return botPersonality.label;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_GameInfoRowData>[
      _GameInfoRowData(label: 'Spielstärke', value: _strengthText),
      _GameInfoRowData(label: 'Eröffnung', value: _openingText),
      _GameInfoRowData(label: 'Persönlichkeit', value: _personalityText),
      _GameInfoRowData(label: 'Kandidaten', value: '$personaCandidateCount'),
      _GameInfoRowData(
        label: 'UCI_ELO Switch',
        value: 'Zug $cpLossUciSwitchFullMoveNumber',
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(205),
          border: Border.all(color: Colors.white.withAlpha(24), width: 1),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows) _GameInfoRow(data: row),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameInfoRow extends StatelessWidget {
  const _GameInfoRow({required this.data});

  final _GameInfoRowData data;

  static const Color _accentColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${data.label}: ',
              style: const TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: data.value,
              style: TextStyle(
                color: Colors.white.withAlpha(225),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameInfoRowData {
  const _GameInfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}
