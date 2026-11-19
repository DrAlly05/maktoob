import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  /// Headings and the Swahili reading text.
  static const String display = 'Fraunces';

  /// Everything else.
  static const String body = 'Inter';

  /// Used when the phone is in dark mode.
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// Used when the phone is in light mode.
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData _build(Palette k, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: k.accent,
      onPrimary: k.onAccent,
      secondary: k.heading,
      onSecondary: k.ground,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: k.ground,
      onSurface: k.text,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: body,
      colorScheme: scheme,
      scaffoldBackgroundColor: k.ground,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: k.card,
        contentTextStyle: TextStyle(
          fontFamily: body,
          fontSize: 14,
          color: k.text,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: k.accent),
    );
  }
}
