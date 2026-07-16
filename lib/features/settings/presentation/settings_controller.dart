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
    final language =
        prefs.getString(_languageKey) ?? (deviceLanguage == 'tr' ? 'tr' : 'en');
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (item) => item.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      ),
      languageCode: language,
      angleMode: prefs.getString(_angleKey) == AngleMode.radians.name
          ? AngleMode.radians
          : AngleMode.degrees,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      keySoundEnabled: prefs.getBool(_soundKey) ?? false,
      decimalPrecision: prefs.getInt(_precisionKey) ?? 10,
      scientificNotation: prefs.getBool(_scientificKey) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await ref.read(sharedPreferencesProvider).setString(_themeKey, value.name);
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(languageCode: value);
    await ref.read(sharedPreferencesProvider).setString(_languageKey, value);
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
    state = state.copyWith(decimalPrecision: value);
    await ref.read(sharedPreferencesProvider).setInt(_precisionKey, value);
  }

  Future<void> setScientificNotation(bool value) async {
    state = state.copyWith(scientificNotation: value);
    await ref.read(sharedPreferencesProvider).setBool(_scientificKey, value);
  }
}
