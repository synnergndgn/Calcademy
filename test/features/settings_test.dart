import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme changes and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).themeMode, ThemeMode.system);
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(preferences.getString('settings.theme'), 'dark');
  });

  test('angle mode changes and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(settingsProvider.notifier)
        .setAngleMode(AngleMode.radians);
    expect(container.read(settingsProvider).angleMode, AngleMode.radians);
    expect(preferences.getString('settings.angle'), 'radians');
  });

  test('corrupt and out-of-range settings fall back safely', () async {
    SharedPreferences.setMockInitialValues({
      'settings.theme': 'unknown',
      'settings.language': 'de',
      'settings.angle': 'unknown',
      'settings.precision': 999,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final settings = container.read(settingsProvider);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.languageCode, isIn(['tr', 'en']));
    expect(settings.angleMode, AngleMode.degrees);
    expect(settings.decimalPrecision, 15);

    await container.read(settingsProvider.notifier).setLanguage('invalid');
    await container.read(settingsProvider.notifier).setPrecision(-100);
    expect(container.read(settingsProvider).languageCode, 'en');
    expect(container.read(settingsProvider).decimalPrecision, 4);
  });
}
