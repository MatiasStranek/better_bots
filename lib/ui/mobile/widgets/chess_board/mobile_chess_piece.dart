import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileChessPiece extends StatelessWidget {
  const MobileChessPiece({super.key, required this.pieceCode});

  final String pieceCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SvgPicture.asset(
        'assets/pieces/$pieceCode.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}
