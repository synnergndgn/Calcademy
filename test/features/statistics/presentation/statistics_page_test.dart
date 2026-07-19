import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const StatisticsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapMode(WidgetTester tester, String label) async {
  await tester.drag(
    find.byKey(const Key('statistics-scroll-view')),
    const Offset(0, 1200),
  );
  await tester.pumpAndSettle();
  final target = find.text(label);
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switches between all three statistics modes', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('stats-data-input')), findsOneWidget);
    await _tapMode(tester, 'Probability Distributions');
    expect(find.byKey(const Key('stats-distribution-kind')), findsOneWidget);
    await _tapMode(tester, 'Confidence Intervals');
    expect(find.byKey(const Key('stats-confidence-kind')), findsOneWidget);
  });

  testWidgets('shows a descriptive result and copy action', (tester) async {
    await _pump(tester);
    await tester.enterText(
      find.byKey(const Key('stats-data-input')),
      '1,2,3,4,5',
    );
    await tester.tap(find.byKey(const Key('stats-descriptive-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('statistics-result-card')));

    expect(find.text('Mean'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.byKey(const Key('stats-copy-result')), findsOneWidget);
  });

  testWidgets('shows distribution and confidence interval results', (
    tester,
  ) async {
    await _pump(tester);
    await _tapMode(tester, 'Probability Distributions');
    await tester.tap(find.byKey(const Key('stats-distribution-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Probability'));
    expect(find.text('0.5'), findsOneWidget);

    await _tapMode(tester, 'Confidence Intervals');
    await tester.tap(find.byKey(const Key('stats-confidence-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Margin of error'));
    expect(find.text('Lower bound'), findsOneWidget);
    expect(find.text('Upper bound'), findsOneWidget);
  });

  testWidgets('shows validation and operation-specific fields', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('stats-descriptive-calculate')));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least one data value.'), findsOneWidget);

    await _tapMode(tester, 'Probability Distributions');
    await tester.tap(find.byKey(const Key('stats-distribution-operation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('P(a ≤ X ≤ b)').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-normal-lower')), findsOneWidget);
    expect(find.byKey(const Key('stats-normal-upper')), findsOneWidget);
    expect(find.byKey(const Key('stats-normal-x')), findsNothing);
  });

  testWidgets('is overflow-free at 320px and 200 percent text scale', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690), scale: 2);
    await _pump(tester, locale: const Locale('tr'));
    expect(tester.takeException(), isNull);
    final scroll = tester.widget<ListView>(
      find.byKey(const Key('statistics-scroll-view')),
    );
    expect((scroll.padding! as EdgeInsets).bottom, greaterThan(16));
    await tester.fling(find.byType(ListView), const Offset(0, -1200), 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds in dark mode', (tester) async {
    await _pump(tester, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(StatisticsPage))).brightness,
      Brightness.dark,
    );
  });
}
