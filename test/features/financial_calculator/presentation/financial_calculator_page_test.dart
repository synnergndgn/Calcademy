import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_calculator_page.dart';
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
        home: const FinancialCalculatorPage(),
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

Future<void> _tapMode(WidgetTester tester, String label) async {
  await tester.drag(
    find.byKey(const Key('financial-scroll-view')),
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

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switches between all financial calculator sections', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('fin-tvm-operation')), findsOneWidget);
    await _tapMode(tester, 'Cash Flows');
    expect(find.byKey(const Key('fin-cash-operation')), findsOneWidget);
    await _tapMode(tester, 'Loan');
    expect(find.byKey(const Key('fin-loan-principal')), findsOneWidget);
    await _tapMode(tester, 'Break-even');
    expect(find.byKey(const Key('fin-break-even-operation')), findsOneWidget);
  });

  testWidgets('calculates TVM and offers a copy action', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('fin-tvm-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('financial-result-card')));

    expect(find.text('Value'), findsOneWidget);
    expect(find.byKey(const Key('fin-copy-result')), findsOneWidget);
  });

  testWidgets('shows only operation-specific TVM fields', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('fin-payment-timing')), findsNothing);
    await tester.tap(find.byKey(const Key('fin-tvm-operation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuity Present Value').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fin-payment-timing')), findsOneWidget);
    expect(find.byKey(const Key('fin-tvm-amount')), findsOneWidget);
  });

  testWidgets('cash flow and loan results expose scrollable tables', (
    tester,
  ) async {
    await _pump(tester);
    await _tapMode(tester, 'Cash Flows');
    await tester.tap(find.byKey(const Key('fin-cash-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('fin-cash-flow-table')));
    expect(find.byKey(const Key('fin-cash-flow-table')), findsOneWidget);
    final cashTableScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('fin-cash-flow-table')),
    );
    expect(cashTableScroll.scrollDirection, Axis.horizontal);
    final cashDataTable = find.descendant(
      of: find.byKey(const Key('fin-cash-flow-table')),
      matching: find.byType(DataTable),
    );
    expect(tester.getSize(cashDataTable).width, greaterThan(400));

    await _tapMode(tester, 'Loan');
    await tester.tap(find.byKey(const Key('fin-loan-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('fin-amortization-table')));
    expect(find.byKey(const Key('fin-amortization-table')), findsOneWidget);
    final loanTableScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('fin-amortization-table')),
    );
    expect(loanTableScroll.scrollDirection, Axis.horizontal);
    final amortizationTable = find.descendant(
      of: find.byKey(const Key('fin-amortization-table')),
      matching: find.byType(DataTable),
    );
    expect(tester.getSize(amortizationTable).width, greaterThan(500));
  });

  testWidgets('break-even calculation renders a typed result', (tester) async {
    await _pump(tester);
    await _tapMode(tester, 'Break-even');
    await tester.tap(find.byKey(const Key('fin-break-even-calculate')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('financial-result-card')));

    expect(find.text('Break-even quantity'), findsOneWidget);
    expect(find.text('Break-even revenue'), findsOneWidget);
  });

  testWidgets('shows validation without crashing', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('fin-tvm-rate')), 'not-number');
    await tester.tap(find.byKey(const Key('fin-tvm-calculate')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('financial-result-card')), findsOneWidget);
    expect(find.text('Enter valid finite numbers.'), findsOneWidget);
  });

  testWidgets('is overflow-free at 320px and 200 percent text scale', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690), scale: 2);
    await _pump(tester, locale: const Locale('tr'));
    expect(tester.takeException(), isNull);

    final scroll = tester.widget<ListView>(
      find.byKey(const Key('financial-scroll-view')),
    );
    expect((scroll.padding! as EdgeInsets).bottom, greaterThan(16));
    await tester.fling(
      find.byKey(const Key('financial-scroll-view')),
      const Offset(0, -1200),
      1000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds in dark mode', (tester) async {
    await _pump(tester, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(FinancialCalculatorPage))).brightness,
      Brightness.dark,
    );
  });
}
