import 'package:calcademy/app/auth/auth_repository_providers.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required bool authConfigured,
}) async {
  SharedPreferences.setMockInitialValues({'settings.language': 'en'});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        isAuthConfiguredProvider.overrideWithValue(authConfigured),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a build without Supabase config hides the Gemini toggle', (
    tester,
  ) async {
    // This is the shipping configuration for the offline release line. A
    // toggle for a feature the build cannot perform reads as broken.
    await _pumpSettings(tester, authConfigured: false);

    expect(find.byKey(const Key('settings-remote-assistant')), findsNothing);
    expect(find.textContaining('Gemini'), findsNothing);
  });

  testWidgets('a configured build offers the Gemini toggle', (tester) async {
    await _pumpSettings(tester, authConfigured: true);

    expect(find.byKey(const Key('settings-remote-assistant')), findsOneWidget);
  });

  testWidgets('the toggle starts off in a configured build', (tester) async {
    await _pumpSettings(tester, authConfigured: true);

    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-remote-assistant')),
    );
    expect(toggle.value, isFalse);
  });
}
