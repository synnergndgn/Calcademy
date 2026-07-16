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
}
