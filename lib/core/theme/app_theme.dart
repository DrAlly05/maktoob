import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  /// Headings and the Swahili reading text.
  static const String display = 'Fraunces';

  /// Everything else.
  static const String body = 'Inter';

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: body,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brass,
        onPrimary: AppColors.night,
        secondary: AppColors.lamp,
        onSecondary: AppColors.night,
        surface: AppColors.night,
        onSurface: AppColors.ivory,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.night,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.raised,
        contentTextStyle: TextStyle(
          fontFamily: body,
          fontSize: 14,
          color: AppColors.ivory,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brass,
      ),
    );
  }
}
