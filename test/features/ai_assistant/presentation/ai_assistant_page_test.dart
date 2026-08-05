import 'package:calcademy/app/premium/premium_surface.dart';
import 'package:calcademy/app/ads/ad_banner.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({'settings.language': 'en'}),
  );

  testWidgets(
    'assistant page renders input, suggestions, local notice, and no ad',
    (tester) async {
      await _pumpPage(tester);

      expect(find.byType(AiAssistantPage), findsOneWidget);
      expect(find.byKey(const Key('ai-assistant-input')), findsOneWidget);
      expect(find.byKey(const Key('ai-assistant-send')), findsOneWidget);
      expect(
        find.byKey(const Key('premium-gate-geminiAssistant')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('premium-badge-locked')), findsOneWidget);
      // Asserted before scrolling: the notice sits at the top of the list, and
      // scrolling far enough to reach the chips unmounts it.
      expect(find.byKey(const Key('ai-scope-notice')), findsOneWidget);
      expect(find.textContaining('local rules'), findsWidgets);
      // A page with no Supabase config must never advertise the remote mode.
      expect(find.textContaining('Gemini API'), findsNothing);
      expect(find.byKey(const Key('ai-remote-consent')), findsNothing);
      await _scrollForwardUntilBuilt(tester, const Key('ai-suggestion-chips'));
      expect(find.byKey(const Key('ai-suggestion-chips')), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(5));
      expect(find.byType(AdBanner), findsNothing);
    },
  );

  testWidgets('mock premium marks Gemini teaser active but still coming soon', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      entitlementRepository: LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.mockPremium(),
      ),
    );

    expect(find.byKey(const Key('premium-badge-active')), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byKey(const Key('ai-assistant-input')), findsOneWidget);
  });

  testWidgets(
    'sending npv shows Financial Calculator, formula, and disclaimer',
    (tester) async {
      await _pumpPage(tester);
      await _send(tester, 'npv');

      await _scrollForwardUntilBuilt(
        tester,
        const Key('ai-financial-disclaimer'),
      );
      expect(find.byKey(const Key('ai-financial-disclaimer')), findsOneWidget);
      await _scrollBackUntilBuilt(
        tester,
        const Key('ai-formula-card-net-present-value'),
      );
      expect(
        find.byKey(const Key('ai-formula-card-net-present-value')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ai-open-formula-net-present-value')),
        findsOneWidget,
      );
      await _scrollBackUntilBuilt(
        tester,
        const Key('ai-tool-card-financial_calculator'),
      );
      expect(
        find.byKey(const Key('ai-tool-card-financial_calculator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ai-open-tool-financial_calculator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('sending determinant shows Matrix suggestion', (tester) async {
    await _pumpPage(tester);
    await _send(tester, 'determinant');

    await _scrollBackUntilBuilt(tester, const Key('ai-tool-card-matrix'));
    expect(find.byKey(const Key('ai-tool-card-matrix')), findsOneWidget);
    await _scrollForwardUntilBuilt(
      tester,
      const Key('ai-formula-card-determinant-2x2'),
    );
    expect(
      find.byKey(const Key('ai-formula-card-determinant-2x2')),
      findsOneWidget,
    );
  });

  testWidgets('out-of-scope request returns the scope boundary', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _send(tester, 'hava durumu');

    expect(
      find.text(
        'This assistant is designed to help only with Calcademy calculation, formula, and learning tools.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ai-tool-card-matrix')), findsNothing);
  });

  testWidgets('tool and formula actions open validated routes', (tester) async {
    final router = GoRouter(
      initialLocation: '/assistant',
      routes: [
        GoRoute(path: '/assistant', builder: (_, _) => const AiAssistantPage()),
        GoRoute(
          path: '/matrix',
          builder: (_, _) => const Scaffold(key: Key('matrix-destination')),
        ),
        GoRoute(
          path: '/formulas/:id',
          builder: (_, state) => Scaffold(
            key: const Key('formula-destination'),
            body: Text(state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpPage(tester, router: router);
    await _send(tester, 'determinant');

    await _scrollBackUntilBuilt(tester, const Key('ai-open-tool-matrix'));
    final toolButton = find.byKey(const Key('ai-open-tool-matrix'));
    await Scrollable.ensureVisible(tester.element(toolButton), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(toolButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('matrix-destination')), findsOneWidget);

    router.go('/assistant');
    await tester.pumpAndSettle();
    await _send(tester, 'determinant');
    await _scrollBackUntilBuilt(
      tester,
      const Key('ai-open-formula-determinant-2x2'),
    );
    final formulaButton = find.byKey(
      const Key('ai-open-formula-determinant-2x2'),
    );
    await Scrollable.ensureVisible(
      tester.element(formulaButton),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(formulaButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('formula-destination')), findsOneWidget);
    expect(find.text('determinant-2x2'), findsOneWidget);
  });

  testWidgets('Home AI quick access opens /assistant', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(path: '/assistant', builder: (_, _) => const AiAssistantPage()),
      ],
    );
    addTearDown(router.dispose);
    await _pumpPage(tester, router: router);

    expect(find.byKey(const Key('quick-access-ai-assistant')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-access-ai-assistant')));
    await tester.pumpAndSettle();
    expect(find.byType(AiAssistantPage), findsOneWidget);
  });

  testWidgets('assistant remains bounded at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(tester);

    expect(tester.takeException(), isNull);
    final input = tester.getRect(find.byKey(const Key('ai-assistant-input')));
    expect(input.left, greaterThanOrEqualTo(16));
    expect(input.right, lessThanOrEqualTo(260));
  });
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('ai-assistant-input')), text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('ai-assistant-send')));
  await tester.pumpAndSettle();
}

Future<void> _scrollBackUntilBuilt(WidgetTester tester, Key key) async {
  for (
    var attempt = 0;
    attempt < 12 && find.byKey(key).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byKey(const Key('ai-assistant-scroll')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollForwardUntilBuilt(WidgetTester tester, Key key) async {
  for (
    var attempt = 0;
    attempt < 12 && find.byKey(key).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byKey(const Key('ai-assistant-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpPage(
  WidgetTester tester, {
  GoRouter? router,
  EntitlementRepository? entitlementRepository,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final effectiveRouter =
      router ??
      GoRouter(
        initialLocation: '/assistant',
        routes: [
          GoRoute(
            path: '/assistant',
            builder: (_, _) => const AiAssistantPage(),
          ),
        ],
      );
  if (router == null) addTearDown(effectiveRouter.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        // The assistant only exists in a Supabase-configured build.
        premiumSurfaceEnabledProvider.overrideWithValue(true),
        if (entitlementRepository != null)
          entitlementRepositoryProvider.overrideWithValue(
            entitlementRepository,
          ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: effectiveRouter,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
