library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF1B6B5A);
  static const Color primaryLight = Color(0xFF2E8B73);
  static const Color primaryDark = Color(0xFF124D41);
  static const Color secondary = Color(0xFFB5853A);
  static const Color secondaryLight = Color(0xFFD4A158);
  static const Color secondaryDark = Color(0xFF8A6129);
  static const Color surfaceLight = Color(0xFFF8F7F4);
  static const Color surfaceContainerLight = Color(0xFFEEEDE9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF242424);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFF29B6F6);

  // Prayer status colours
  static const Color prayedColor = Color(0xFF2E7D32);
  static const Color missedColor = Color(0xFFC62828);
  static const Color notRecordedColor = Color(0xFF9E9E9E);
  static const Color prayedLateColor = Color(0xFF00897B);
  static const Color qadaCompletedColor = Color(0xFFF57C00); // teal

  static const Color premiumGold = Color(0xFFB5853A);
  static const Color premiumGoldLight = Color(0xFFD4A158);

  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0x1A000000);
}

extension AppColorsScheme on AppColors {
  static ColorScheme lightScheme() => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      );

  static ColorScheme darkScheme() => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceDark,
        error: AppColors.errorLight,
      );
}
