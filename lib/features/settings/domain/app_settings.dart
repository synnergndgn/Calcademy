import 'package:flutter/material.dart';

enum AngleMode { degrees, radians }

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.languageCode,
    required this.angleMode,
    required this.hapticsEnabled,
    required this.keySoundEnabled,
    required this.decimalPrecision,
    required this.scientificNotation,
  });

  final ThemeMode themeMode;
  final String languageCode;
  final AngleMode angleMode;
  final bool hapticsEnabled;
  final bool keySoundEnabled;
  final int decimalPrecision;
  final bool scientificNotation;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    AngleMode? angleMode,
    bool? hapticsEnabled,
    bool? keySoundEnabled,
    int? decimalPrecision,
    bool? scientificNotation,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      angleMode: angleMode ?? this.angleMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      keySoundEnabled: keySoundEnabled ?? this.keySoundEnabled,
      decimalPrecision: decimalPrecision ?? this.decimalPrecision,
      scientificNotation: scientificNotation ?? this.scientificNotation,
    );
  }
}
