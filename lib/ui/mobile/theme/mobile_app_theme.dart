import 'package:flutter/material.dart';

class MobileAppTheme {
  const MobileAppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111111),
    );
  }
}
