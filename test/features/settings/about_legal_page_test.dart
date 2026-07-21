import 'dart:io';

import 'package:calcademy/app/app_metadata.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/settings/presentation/about_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('About & Legal presents app, privacy, and responsible-use info', (
    tester,
  ) async {
    await _pumpAbout(tester);

    expect(find.text('Calcademy'), findsOneWidget);
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    expect(find.text('Privacy & data handling'), findsOneWidget);
    expect(find.text('Local storage'), findsOneWidget);
    expect(find.text('No ads'), findsOneWidget);
    expect(find.text('No analytics'), findsOneWidget);
    expect(find.text('No cloud sync'), findsOneWidget);
    expect(find.text('No account'), findsOneWidget);
    expect(find.text('Local-first'), findsOneWidget);
    expect(find.text('Financial disclaimer'), findsOneWidget);
    expect(find.byKey(const Key('copy-app-info-action')), findsOneWidget);
    expect(find.byKey(const Key('open-privacy-policy-action')), findsOneWidget);
    expect(find.text('Open Privacy Policy'), findsOneWidget);
    expect(find.text('Contact'), findsNothing);
    expect(find.text('Open-source packages'), findsWidgets);
  });

  testWidgets('privacy action launches the verified URL externally', (
    tester,
  ) async {
    Uri? launchedUri;
    await _pumpAbout(
      tester,
      page: AboutPage(
        externalUrlLauncher: (uri) async {
          launchedUri = uri;
          return true;
        },
      ),
    );

    final action = find.byKey(const Key('open-privacy-policy-action'));
    await _scrollAboutTo(tester, action);
    await tester.tap(action);
    await tester.pump();

    expect(launchedUri, AppMetadata.privacyPolicyUri);
    expect(find.text('Privacy policy could not be opened.'), findsNothing);
  });

  testWidgets('privacy launch failure shows localized feedback', (
    tester,
  ) async {
    await _pumpAbout(
      tester,
      page: AboutPage(externalUrlLauncher: (_) async => false),
    );

    final action = find.byKey(const Key('open-privacy-policy-action'));
    await _scrollAboutTo(tester, action);
    await tester.tap(action);
    await tester.pump();

    expect(
      find.text('The privacy policy could not be opened. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('missing privacy URL hides action but keeps local summary', (
    tester,
  ) async {
    await _pumpAbout(tester, page: const AboutPage(privacyPolicyUrl: null));

    expect(find.byKey(const Key('open-privacy-policy-action')), findsNothing);
    expect(find.text('Privacy & data handling'), findsOneWidget);
    expect(
      find.textContaining('processes calculation inputs on this device'),
      findsOneWidget,
    );
  });

  testWidgets('copy app info uses localized release metadata', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpAbout(tester);

    await tester.tap(find.byKey(const Key('copy-app-info-action')));
    await tester.pump();

    expect(copiedText, contains(AppMetadata.appName));
    expect(copiedText, contains('Version 1.0.0 (1)'));
    expect(copiedText, contains(AppMetadata.publisherName));
    expect(copiedText, contains(AppMetadata.applicationId));
    expect(copiedText, contains('No ads'));
    expect(find.text('App info copied.'), findsOneWidget);
  });

  testWidgets('Home About action opens the existing About route', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: _app(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-about-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-about-action')));
    await tester.pumpAndSettle();

    expect(find.byType(AboutPage), findsOneWidget);
    expect(find.text('About & Legal'), findsOneWidget);
  });

  testWidgets('About remains bounded and scrollable at 320px and 200% text', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690), scale: 2);
    await _pumpAbout(tester);

    expect(tester.takeException(), isNull);
    final privacy = find.byKey(const Key('about-privacy-section'));
    final privacyRect = tester.getRect(privacy);
    expect(privacyRect.left, greaterThanOrEqualTo(16));
    expect(privacyRect.right, lessThanOrEqualTo(304));

    await tester.scrollUntilVisible(
      find.byKey(const Key('about-legal-section')),
      350,
      scrollable: find.descendant(
        of: find.byKey(const Key('about-legal-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Financial disclaimer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final list = tester.widget<ListView>(
      find.byKey(const Key('about-legal-scroll')),
    );
    expect((list.padding! as EdgeInsets).bottom, greaterThan(24));
  });

  testWidgets('About builds with readable dark theme surfaces', (tester) async {
    await _pumpAbout(tester, dark: true);

    final theme = Theme.of(tester.element(find.byType(AboutPage)));
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.colorScheme.onSurface.computeLuminance(),
      greaterThan(theme.colorScheme.surface.computeLuminance()),
    );
    expect(tester.takeException(), isNull);
  });

  test('About & Legal localization keys have English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'aboutLegal',
      'versionLabel',
      'publisherLabel',
      'applicationIdLabel',
      'copyAppInfo',
      'appInfoCopied',
      'localFirst',
      'dataHandling',
      'privacyPolicy',
      'openPrivacyPolicy',
      'privacyPolicyOpenError',
      'privacyPolicyBody',
      'localStorage',
      'localStorageBody',
      'noAds',
      'noAnalytics',
      'noCloudSync',
      'noAccount',
      'educationalUse',
      'educationalUseBody',
      'financialDisclaimer',
      'financialDisclaimerBody',
      'contact',
      'contactBody',
      'openSourceLicensesBody',
    ];

    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
    expect(turkish.t('openPrivacyPolicy'), 'Gizlilik Politikasını Aç');
  });

  test('central app metadata matches pubspec version', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    expect(
      pubspec,
      contains(
        'version: ${AppMetadata.versionName}+${AppMetadata.versionCode}',
      ),
    );
    expect(pubspec, contains('description: "${AppMetadata.tagline}"'));
    expect(AppMetadata.appName, 'Calcademy');
    expect(AppMetadata.applicationId, 'com.aligundogan.calcademy');
    expect(AppMetadata.publisherName, 'Ali Gündoğan');
    expect(AppMetadata.privacyStatus, 'local-first');
    expect(AppMetadata.adsStatus, 'not-included');
    expect(AppMetadata.analyticsStatus, 'not-included');
    expect(AppMetadata.cloudSyncStatus, 'not-included');
    expect(
      AppMetadata.privacyPolicyUrl,
      'https://synnergndgn.github.io/Calcademy/privacy_policy',
    );
    expect(
      AppMetadata.privacyPolicyUri,
      Uri.parse('https://synnergndgn.github.io/Calcademy/privacy_policy'),
    );
    expect(AppMetadata.parsePublicHttpsUrl(null), isNull);
    expect(AppMetadata.parsePublicHttpsUrl(''), isNull);
    expect(AppMetadata.parsePublicHttpsUrl('http://calcademy.dev'), isNull);
    expect(
      AppMetadata.parsePublicHttpsUrl('https://example.com/privacy'),
      isNull,
    );
    expect(
      AppMetadata.parsePublicHttpsUrl('https://user@example.dev/privacy'),
      isNull,
    );
    expect(AppMetadata.contactEmail, isNull);
    expect(AppMetadata.repositoryUrl, isNull);
    expect(AppMetadata.privacyPolicyEffectiveDate, '2026-07-21');
  });

  test(
    'final Android package identity and decision record are aligned',
    () async {
      final gradle = await File('android/app/build.gradle.kts').readAsString();
      final manifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      final mainActivity = await File(
        'android/app/src/main/kotlin/com/aligundogan/calcademy/MainActivity.kt',
      ).readAsString();
      final decision = await File(
        'docs/package_name_decision.md',
      ).readAsString();

      expect(gradle, contains('namespace = "com.aligundogan.calcademy"'));
      expect(gradle, contains('applicationId = "com.aligundogan.calcademy"'));
      expect(gradle, isNot(contains('com.calcademy.calcademy')));
      expect(manifest, contains('android:name=".MainActivity"'));
      expect(mainActivity, contains('package com.aligundogan.calcademy'));
      expect(
        File(
          'android/app/src/main/kotlin/com/calcademy/calcademy/MainActivity.kt',
        ).existsSync(),
        isFalse,
      );
      expect(decision, contains('**`com.aligundogan.calcademy`**'));
      expect(decision, contains('| Applied in code | **Yes** |'));
    },
  );

  test('adaptive launcher resources use the Calcademy brand mark', () async {
    final legacy = await File(
      'android/app/src/main/res/mipmap-anydpi/ic_launcher.xml',
    ).readAsString();
    final adaptive = await File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsString();
    final themed = await File(
      'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
    ).readAsString();
    final foreground = await File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    ).readAsString();
    final colors = await File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsString();

    expect(legacy, contains('official Calcademy SVG mark'));
    expect(legacy, contains('#63897A'));
    expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    expect(adaptive, contains('@color/launcher_icon_background'));
    expect(themed, contains('<monochrome'));
    expect(foreground, contains('#FBFAF5'));
    expect(foreground, contains('#E7B77D'));
    expect(colors, contains('#63897A'));
  });
}

Future<void> _pumpAbout(
  WidgetTester tester, {
  bool dark = false,
  Widget page = const AboutPage(),
}) async {
  await tester.pumpWidget(_app(home: page, dark: dark));
  await tester.pumpAndSettle();
}

Future<void> _scrollAboutTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.descendant(
      of: find.byKey(const Key('about-legal-scroll')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app({
  Widget? home,
  RouterConfig<Object>? routerConfig,
  bool dark = false,
}) {
  const delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (routerConfig != null) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      routerConfig: routerConfig,
    );
  }
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: delegates,
    home: home,
  );
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
