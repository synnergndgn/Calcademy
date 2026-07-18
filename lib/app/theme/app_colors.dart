import 'package:flutter/material.dart';

abstract final class AppColors {
  static const sage = Color(0xFF8FAE9E);
  static const forest = Color(0xFF63897A);
  static const warmWhite = Color(0xFFFBFAF5);
  static const dataPoint = Color(0xFFE7B77D);

  static const _lightInk = Color(0xFF1B2822);
  static const _darkSurface = Color(0xFF101713);

  static ColorScheme lightScheme() {
    return ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: forest,
      onPrimary: warmWhite,
      primaryContainer: const Color(0xFFDCE9E2),
      onPrimaryContainer: const Color(0xFF17382C),
      secondary: const Color(0xFF587267),
      onSecondary: warmWhite,
      secondaryContainer: const Color(0xFFD5E5DC),
      onSecondaryContainer: const Color(0xFF203A30),
      tertiary: const Color(0xFF8C572C),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF8E2CA),
      onTertiaryContainer: const Color(0xFF4C2C12),
      surface: warmWhite,
      onSurface: _lightInk,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF5F3ED),
      surfaceContainer: const Color(0xFFEFEFE8),
      surfaceContainerHigh: const Color(0xFFE7EAE3),
      surfaceContainerHighest: const Color(0xFFDDE4DE),
      outline: const Color(0xFF6F7973),
      outlineVariant: const Color(0xFFC0C9C3),
    );
  }

  static ColorScheme darkScheme() {
    return ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFAFCBBD),
      onPrimary: const Color(0xFF14352A),
      primaryContainer: const Color(0xFF34594B),
      onPrimaryContainer: const Color(0xFFD1EBDD),
      secondary: const Color(0xFFB8C9C0),
      onSecondary: const Color(0xFF263C33),
      secondaryContainer: const Color(0xFF3B5047),
      onSecondaryContainer: const Color(0xFFD4E7DC),
      tertiary: const Color(0xFFF0C999),
      onTertiary: const Color(0xFF4B2C10),
      tertiaryContainer: const Color(0xFF60401F),
      onTertiaryContainer: const Color(0xFFFFDFC0),
      surface: _darkSurface,
      onSurface: const Color(0xFFF2F2EB),
      surfaceContainerLowest: const Color(0xFF0A100D),
      surfaceContainerLow: const Color(0xFF171F1B),
      surfaceContainer: const Color(0xFF1B2420),
      surfaceContainerHigh: const Color(0xFF25302B),
      surfaceContainerHighest: const Color(0xFF303B36),
      outline: const Color(0xFF89948E),
      outlineVariant: const Color(0xFF3F4A45),
    );
  }
}
