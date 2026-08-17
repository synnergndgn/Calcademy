import 'dart:ui';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'settings.theme';
  static const _languageKey = 'settings.language';
  static const _angleKey = 'settings.angle';
  static const _hapticsKey = 'settings.haptics';
  static const _soundKey = 'settings.sound';
  static const _precisionKey = 'settings.precision';
  static const _scientificKey = 'settings.scientific';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    final storedLanguage = _safeRead(() => prefs.getString(_languageKey));
    final language = storedLanguage == 'tr' || storedLanguage == 'en'
        ? storedLanguage!
        : (deviceLanguage == 'tr' ? 'tr' : 'en');
    final storedTheme = _safeRead(() => prefs.getString(_themeKey));
    final storedAngle = _safeRead(() => prefs.getString(_angleKey));
    final storedPrecision = _safeRead(() => prefs.getInt(_precisionKey));
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (item) => item.name == storedTheme,
        orElse: () => ThemeMode.system,
      ),
      languageCode: language,
      angleMode: storedAngle == AngleMode.radians.name
          ? AngleMode.radians
          : AngleMode.degrees,
      hapticsEnabled: _safeRead(() => prefs.getBool(_hapticsKey)) ?? true,
      keySoundEnabled: _safeRead(() => prefs.getBool(_soundKey)) ?? false,
      decimalPrecision: (storedPrecision ?? 10).clamp(4, 15),
      scientificNotation:
          _safeRead(() => prefs.getBool(_scientificKey)) ?? true,
    );
  }

  T? _safeRead<T>(T? Function() read) {
    try {
      return read();
    } on Object {
      return null;
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await ref.read(sharedPreferencesProvider).setString(_themeKey, value.name);
  }

  Future<void> setLanguage(String value) async {
    final language = value == 'tr' ? 'tr' : 'en';
    state = state.copyWith(languageCode: language);
    await ref.read(sharedPreferencesProvider).setString(_languageKey, language);
  }

  Future<void> setAngleMode(AngleMode value) async {
    state = state.copyWith(angleMode: value);
    await ref.read(sharedPreferencesProvider).setString(_angleKey, value.name);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await ref.read(sharedPreferencesProvider).setBool(_hapticsKey, value);
  }

  Future<void> setKeySound(bool value) async {
    state = state.copyWith(keySoundEnabled: value);
    await ref.read(sharedPreferencesProvider).setBool(_soundKey, value);
  }

  Future<void> setPrecision(int value) async {
    final precision = value.clamp(4, 15);
    state = state.copyWith(decimalPrecision: precision);
    await ref.read(sharedPreferencesProvider).setInt(_precisionKey, precision);
  }

  Future<void> setScientificNotation(bool value) async {
    state = state.copyWith(scientificNotation: value);
    await ref.read(sharedPreferencesProvider).setBool(_scientificKey, value);
  }
}
