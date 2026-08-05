import 'package:calcademy/app/premium/premium_surface.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ad-supported release is compiled without Supabase config. In that build
/// accounts, subscriptions, the assistant, and the camera solver must not
/// exist anywhere in the UI — a free user should never meet a door that does
/// not open.
Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required bool premiumSurface,
}) async {
  SharedPreferences.setMockInitialValues({'settings.language': 'en'});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        premiumSurfaceEnabledProvider.overrideWithValue(premiumSurface),
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
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('module visibility', () {
    test('the free build drops every premium-surface module', () {
      final free = visibleAcademyModules(
        premiumSurface: false,
      ).map((module) => module.id).toList();

      expect(free, isNot(contains('premium')));
      expect(free, isNot(contains('ai-assistant')));
      expect(free, isNot(contains('camera-solver')));
    });

    test('the free build keeps every calculation module', () {
      final free = visibleAcademyModules(
        premiumSurface: false,
      ).map((module) => module.id).toList();

      for (final id in const [
        'calculator',
        'graphing',
        'matrices',
        'equations',
        'calculus',
        'statistics',
        'financial-calculator',
        'linear-programming',
        'integer-programming',
        'operations-research',
        'formula-library',
        'saved',
      ]) {
        expect(free, contains(id), reason: id);
      }
    });

    test('a configured build keeps everything', () {
      expect(
        visibleAcademyModules(premiumSurface: true).length,
        academyModules.length,
      );
    });

    test('quick access drops the assistant in the free build', () {
      expect(
        visibleQuickAccessModuleIds(premiumSurface: false),
        isNot(contains('ai-assistant')),
      );
      expect(
        visibleQuickAccessModuleIds(premiumSurface: true),
        contains('ai-assistant'),
      );
    });

    test('quick access keeps its remaining order', () {
      expect(visibleQuickAccessModuleIds(premiumSurface: false), [
        'calculator',
        'graphing',
        'matrices',
        'equations',
        'formula-library',
        'saved',
      ]);
    });
  });

  group('Home in the free build', () {
    testWidgets('shows no assistant, premium, or camera entry', (tester) async {
      await _pump(tester, const HomePage(), premiumSurface: false);

      expect(find.byKey(const Key('quick-access-ai-assistant')), findsNothing);
      expect(find.text('Ask Calcademy'), findsNothing);
      expect(find.text('Calcademy Premium'), findsNothing);
      expect(find.text('Camera Solver'), findsNothing);
    });

    testWidgets('still shows the calculation modules', (tester) async {
      await _pump(tester, const HomePage(), premiumSurface: false);

      expect(find.byKey(const Key('quick-access-calculator')), findsOneWidget);
      expect(find.byKey(const Key('home-quick-access-header')), findsOneWidget);
    });

    testWidgets('a configured build shows the assistant again', (tester) async {
      await _pump(tester, const HomePage(), premiumSurface: true);

      expect(
        find.byKey(const Key('quick-access-ai-assistant')),
        findsOneWidget,
      );
    });
  });

  group('Settings in the free build', () {
    testWidgets('hides the account, premium, and assistant rows', (
      tester,
    ) async {
      await _pump(tester, const SettingsPage(), premiumSurface: false);

      expect(find.byKey(const Key('settings-account-tile')), findsNothing);
      expect(find.byKey(const Key('settings-premium-tile')), findsNothing);
      expect(find.byKey(const Key('settings-remote-assistant')), findsNothing);
    });

    testWidgets('leaks no backend wording to a free user', (tester) async {
      await _pump(tester, const SettingsPage(), premiumSurface: false);

      expect(find.textContaining('Supabase'), findsNothing);
      expect(find.textContaining('Gemini'), findsNothing);
    });

    testWidgets('a configured build shows all three rows', (tester) async {
      await _pump(tester, const SettingsPage(), premiumSurface: true);

      // Settings is long; the account and premium rows sit below the fold.
      for (final key in const [
        Key('settings-remote-assistant'),
        Key('settings-account-tile'),
        Key('settings-premium-tile'),
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(key),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(key), findsOneWidget);
      }
    });
  });
}
