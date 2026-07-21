import 'package:flutter/material.dart';

import '../../../data/better_bots_database.dart';
import '../../../widgets/chess_result_stats_panel.dart';

class MobileChessResultStatsPanel extends StatelessWidget {
  const MobileChessResultStatsPanel({
    super.key,
    required this.counter,
    this.trainedOnly = false,
  });

  final TrainingCounterSnapshot counter;
  final bool trainedOnly;

  @override
  Widget build(BuildContext context) {
    return ChessResultStatsPanel(
      counter: counter,
      trainedOnly: trainedOnly,
    );
  }
}
