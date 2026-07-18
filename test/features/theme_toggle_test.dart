import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('system light mode shows the switch-to-dark moon icon', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      systemBrightness: Brightness.light,
      initialValues: const {},
    );

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_rounded), findsNothing);
  });

  testWidgets('system dark mode shows the switch-to-light sun icon', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      systemBrightness: Brightness.dark,
      initialValues: const {},
    );

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);
  });

  testWidgets('manual theme overrides system brightness for the quick icon', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      systemBrightness: Brightness.dark,
      initialValues: const {'settings.theme': 'light'},
    );
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await _pumpHome(
      tester,
      systemBrightness: Brightness.light,
      initialValues: const {'settings.theme': 'dark'},
    );
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });

  testWidgets('quick toggle updates icon through light dark light changes', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      systemBrightness: Brightness.light,
      initialValues: const {'settings.theme': 'light'},
    );

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Brightness systemBrightness,
  required Map<String, Object> initialValues,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = systemBrightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  SharedPreferences.setMockInitialValues(initialValues);
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) {
          final themeMode = ref.watch(
            settingsProvider.select((settings) => settings.themeMode),
          );
          return MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomePage(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}
