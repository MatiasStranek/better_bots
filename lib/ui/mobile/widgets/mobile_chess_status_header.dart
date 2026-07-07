import 'package:flutter/material.dart';

class MobileChessStatusHeader extends StatelessWidget {
  const MobileChessStatusHeader({
    super.key,
    required this.statusText,
    this.height = 48,
  });

  final String statusText;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border(
            bottom: BorderSide(color: Colors.white.withAlpha(18), width: 1),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
