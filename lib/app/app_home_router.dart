import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../pages/chess_board_page.dart';
import '../ui/mobile/pages/mobile_chess_board_page.dart';

class AppHomeRouter extends StatelessWidget {
  const AppHomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    if (isMobilePlatform) {
      return const MobileChessBoardPage();
    }

    return const ChessBoardPage();
  }
}
