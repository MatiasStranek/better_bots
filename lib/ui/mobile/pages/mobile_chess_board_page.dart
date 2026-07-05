import 'package:flutter/material.dart';

import '../layouts/mobile_chess_board_layout.dart';

class MobileChessBoardPage extends StatelessWidget {
  const MobileChessBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111111),
      body: SafeArea(child: MobileChessBoardLayout()),
    );
  }
}
