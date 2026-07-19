import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_home_page.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_page.dart';
import 'package:calcademy/features/optimization/presentation/widgets/responsive_constraint_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Geometry-level checks for the shared constraint card in both the LP and
/// IP editors: the relation and RHS fields must always sit inside the
/// viewport (never behind a horizontal scroll), while the coefficient
/// cells live in their own independent horizontal Scrollable.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder relationFieldOf(String module) => find.byWidgetPredicate(
    (w) => w.key != null && w.key.toString().contains('$module-relation-'),
  );
  Finder rhsFieldOf(String module) => find.byWidgetPredicate(
    (w) => w.key != null && w.key.toString().contains('$module-rhs-'),
  );
  Finder cellOf(String module) => find.byWidgetPredicate(
    (w) => w.key != null && w.key.toString().contains('$module-cell-'),
  );

  Future<void> pumpModule(
    WidgetTester tester,
    Widget home, {
    ThemeData? theme,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          integerProgramSolveExecutorProvider.overrideWithValue(
            (program) async => const BranchAndBoundSolver().solve(program),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void setPhone(
    WidgetTester tester, {
    double width = 320,
    double scale = 1.0,
    double height = 690,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> showConstraintCard(WidgetTester tester) async {
    // The page ListView builds lazily, so the constraint cards may not be
    // in the tree yet; scroll in fixed steps until one appears, then bring
    // it fully on screen.
    final card = find.byWidgetPredicate((w) => w is ResponsiveConstraintCard);
    for (var i = 0; i < 10 && card.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(card.first);
    await tester.pumpAndSettle();
  }

  void expectInsideViewport(WidgetTester tester, Finder finder, double width) {
    final rect = tester.getRect(finder.first);
    expect(
      rect.right,
      lessThanOrEqualTo(width),
      reason: 'right edge ${rect.right} exceeds viewport $width',
    );
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.width, greaterThan(60), reason: 'field unusably narrow');
  }

  testWidgets('LP at 320px with 2 variables keeps relation and RHS in view', (
    tester,
  ) async {
    setPhone(tester);
    await pumpModule(tester, const LinearProgramPage());
    await showConstraintCard(tester);
    expectInsideViewport(tester, relationFieldOf('lp'), 320);
    expectInsideViewport(tester, rhsFieldOf('lp'), 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'LP at 320px with 10 variables scrolls coefficients independently',
    (tester) async {
      setPhone(tester);
      await pumpModule(tester, const LinearProgramPage());
      final addVariable = find.byTooltip('Add variable');
      for (var i = 0; i < 10 && addVariable.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(addVariable);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.tap(addVariable);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await showConstraintCard(tester);

      // Coefficient cells sit inside their own horizontal Scrollable...
      final horizontalScrollables = find.ancestor(
        of: cellOf('lp').first,
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      );
      expect(horizontalScrollables, findsWidgets);

      // ...and that Scrollable is NOT an ancestor of the relation field.
      final relationInStrip = find.ancestor(
        of: relationFieldOf('lp').first,
        matching: horizontalScrollables.first,
      );
      expect(relationInStrip, findsNothing);

      // Relation and RHS remain fully in the viewport without scrolling.
      expectInsideViewport(tester, relationFieldOf('lp'), 320);
      expectInsideViewport(tester, rhsFieldOf('lp'), 320);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('IP at 320px keeps relation and RHS in view for a mixed model', (
    tester,
  ) async {
    setPhone(tester);
    await pumpModule(tester, const IntegerProgramHomePage());
    await showConstraintCard(tester);
    expectInsideViewport(tester, relationFieldOf('mip'), 320);
    expectInsideViewport(tester, rhsFieldOf('mip'), 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% text scale produces no overflow in either editor', (
    tester,
  ) async {
    setPhone(tester, scale: 2.0);
    await pumpModule(tester, const LinearProgramPage());
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await pumpModule(tester, const IntegerProgramHomePage());
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('adding a constraint produces exactly one more card', (
    tester,
  ) async {
    // Tall viewport so the lazily built ListView holds every card at once
    // and the card count is exact rather than viewport-dependent.
    setPhone(tester, width: 412, height: 2600);
    await pumpModule(tester, const IntegerProgramHomePage());
    expect(
      find.byWidgetPredicate((w) => w is ResponsiveConstraintCard),
      findsOneWidget,
    );
    expect(find.text('1/20'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mip-add-constraint')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is ResponsiveConstraintCard),
      findsNWidgets(2),
    );
    expect(find.text('2/20'), findsOneWidget);
  });

  testWidgets('copying a constraint copies values but mints a new identity', (
    tester,
  ) async {
    setPhone(tester, width: 412);
    await pumpModule(tester, const IntegerProgramHomePage());
    await showConstraintCard(tester);

    final firstCell = cellOf('mip').first;
    await tester.enterText(firstCell, '7');
    await tester.pump();

    await tester.tap(find.byTooltip('Copy constraint'));
    await tester.pumpAndSettle();

    final cards = find.byWidgetPredicate((w) => w is ResponsiveConstraintCard);
    expect(cards, findsNWidgets(2));
    final keys = [for (final e in cards.evaluate()) (e.widget.key!).toString()];
    expect(keys.toSet(), hasLength(2), reason: 'copy must have a new ID');

    // Both cards' first coefficient cells show the copied value, but they
    // are backed by distinct controllers.
    final cellWidgets = [
      for (final e in cellOf('mip').evaluate()) e.widget as TextField,
    ];
    final firstOfEachCard = [
      cellWidgets.first,
      cellWidgets[cellWidgets.length ~/ 2],
    ];
    expect(firstOfEachCard[0].controller!.text, '7');
    expect(firstOfEachCard[1].controller!.text, '7');
    expect(
      identical(firstOfEachCard[0].controller, firstOfEachCard[1].controller),
      isFalse,
      reason: 'copied constraint must not share controller objects',
    );
  });

  testWidgets('deleting removes the correct card and keeps other values', (
    tester,
  ) async {
    setPhone(tester, width: 412);
    await pumpModule(tester, const IntegerProgramHomePage());
    await showConstraintCard(tester);

    // Card 1: coefficient 5. Copy it (card 2 gets 5 too), change card 2 to 9.
    await tester.enterText(cellOf('mip').first, '5');
    await tester.pump();
    await tester.tap(find.byTooltip('Copy constraint'));
    await tester.pumpAndSettle();
    final secondCardFirstCell = cellOf('mip').at(2);
    await tester.enterText(secondCardFirstCell, '9');
    await tester.pump();

    // Delete card 1; the surviving card must be the one holding 9.
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is ResponsiveConstraintCard),
      findsOneWidget,
    );
    final survivor = cellOf('mip').first.evaluate().single.widget as TextField;
    expect(survivor.controller!.text, '9');
  });

  testWidgets('delete is disabled on the last remaining constraint', (
    tester,
  ) async {
    setPhone(tester, width: 412);
    await pumpModule(tester, const IntegerProgramHomePage());
    await showConstraintCard(tester);
    final deleteButton = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byIcon(Icons.delete_outline).first,
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets(
    'adding and removing a variable keeps coefficient cells in sync',
    (tester) async {
      setPhone(tester, width: 412);
      await pumpModule(tester, const IntegerProgramHomePage());
      await showConstraintCard(tester);
      final before = cellOf('mip').evaluate().length;

      await tester.ensureVisible(find.byTooltip('Add variable'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add variable'));
      await tester.pumpAndSettle();
      await showConstraintCard(tester);
      expect(cellOf('mip').evaluate().length, before + 1);

      await tester.ensureVisible(find.byTooltip('Remove variable'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove variable'));
      await tester.pumpAndSettle();
      await showConstraintCard(tester);
      expect(
        cellOf('mip').evaluate().length,
        before,
        reason: 'no stale coefficient cell may remain',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark mode builds both constraint editors', (tester) async {
    setPhone(tester, width: 412);
    await pumpModule(tester, const LinearProgramPage(), theme: AppTheme.dark());
    await showConstraintCard(tester);
    expect(tester.takeException(), isNull);
    await pumpModule(
      tester,
      const IntegerProgramHomePage(),
      theme: AppTheme.dark(),
    );
    await showConstraintCard(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete icon lives in the card header, above the fields', (
    tester,
  ) async {
    setPhone(tester, width: 412);
    await pumpModule(tester, const IntegerProgramHomePage());
    await showConstraintCard(tester);
    final deleteRect = tester.getRect(find.byIcon(Icons.delete_outline).first);
    final firstCellRect = tester.getRect(cellOf('mip').first);
    final rhsRect = tester.getRect(rhsFieldOf('mip').first);
    expect(
      deleteRect.bottom,
      lessThanOrEqualTo(firstCellRect.top),
      reason: 'delete belongs to the header, above the coefficient strip',
    );
    expect(
      firstCellRect.bottom,
      lessThanOrEqualTo(rhsRect.top),
      reason: 'relation/RHS row sits below the coefficient strip',
    );
  });

  group('coefficient strip scroll hints', () {
    // Builds the LP editor with 10 variables at 320px so the strip
    // overflows, then drives the strip's own ScrollPosition directly
    // (gesture-based drags on a row of TextFields are ambiguous in the
    // gesture arena and would make these tests flaky).
    Future<ScrollPosition> setUpOverflowingStrip(WidgetTester tester) async {
      setPhone(tester);
      await pumpModule(tester, const LinearProgramPage());
      final addVariable = find.byTooltip('Add variable');
      for (var i = 0; i < 10 && addVariable.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(addVariable);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.tap(addVariable);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await showConstraintCard(tester);
      final stripScrollable = find
          .ancestor(of: cellOf('lp').first, matching: find.byType(Scrollable))
          .first;
      return tester.state<ScrollableState>(stripScrollable).position;
    }

    testWidgets('no always-visible scrollbar overlays the inputs', (
      tester,
    ) async {
      await setUpOverflowingStrip(tester);
      final card = find
          .byWidgetPredicate((w) => w is ResponsiveConstraintCard)
          .first;
      expect(
        find.descendant(of: card, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.byType(RawScrollbar)),
        findsNothing,
      );
    });

    testWidgets('at the start only the right hint shows', (tester) async {
      await setUpOverflowingStrip(tester);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('scrolling away from the start reveals the left hint', (
      tester,
    ) async {
      final position = await setUpOverflowingStrip(tester);
      position.jumpTo(position.maxScrollExtent / 2);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('reaching the end hides the right hint', (tester) async {
      final position = await setUpOverflowingStrip(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.chevron_left), findsWidgets);
    });

    testWidgets('hints sit inside IgnorePointer and do not block input', (
      tester,
    ) async {
      final position = await setUpOverflowingStrip(tester);
      position.jumpTo(position.maxScrollExtent / 2);
      await tester.pumpAndSettle();

      for (final chevron in [Icons.chevron_left, Icons.chevron_right]) {
        expect(
          find.ancestor(
            of: find.byIcon(chevron).first,
            matching: find.byType(IgnorePointer),
          ),
          findsWidgets,
          reason: '$chevron hint must not participate in hit testing',
        );
      }

      // Tap a point inside the left hint zone that overlaps a coefficient
      // cell; the tap must land on the TextField, not the hint. The hint
      // zone spans the first 28px of the strip itself, not of the screen.
      final stripRect = tester.getRect(
        find
            .ancestor(of: cellOf('lp').first, matching: find.byType(Scrollable))
            .first,
      );
      final hintZoneRight = stripRect.left + 28;
      final cells = cellOf('lp');
      Rect? overlap;
      for (var i = 0; i < cells.evaluate().length; i++) {
        final rect = tester.getRect(cells.at(i));
        final zone = Rect.fromLTRB(
          stripRect.left,
          rect.top,
          hintZoneRight,
          rect.bottom,
        ).intersect(rect);
        if (zone.width > 4) {
          overlap = zone;
          break;
        }
      }
      expect(
        overlap,
        isNotNull,
        reason: 'expected a cell under the left hint zone',
      );
      await tester.tapAt(overlap!.center);
      await tester.pump();
      final focused = find.byWidgetPredicate(
        (w) => w is EditableText && w.focusNode.hasFocus,
      );
      expect(
        focused,
        findsOneWidget,
        reason: 'the cell under the hint must receive the tap',
      );
    });
  });

  group('coefficient floating label clipping', () {
    // The app theme uses OutlineInputBorder, whose floating label paints
    // centred on the field's top border - i.e. its upper half extends
    // above the field box. The strip clips to the scroll view's bounds,
    // so the label must have headroom inside those bounds or it is shaved
    // on device. These tests assert real geometry, not just "no crash".
    Finder stripLabelText(String data, Finder strip) => find.descendant(
      of: strip,
      matching: find.byWidgetPredicate((w) => w is Text && w.data == data),
    );

    Finder stripOf(String module, WidgetTester tester, Finder cellFinder) =>
        find.ancestor(of: cellFinder.first, matching: find.byType(Scrollable));

    Future<void> expectLabelsUnclipped(
      WidgetTester tester,
      String module,
    ) async {
      final cells = cellOf(module);
      final strip = stripOf(module, tester, cells).first;
      final stripRect = tester.getRect(strip);
      for (final label in ['x1', 'x2']) {
        final labelFinder = stripLabelText(label, strip);
        expect(labelFinder, findsWidgets, reason: 'label $label missing');
        final labelRect = tester.getRect(labelFinder.first);
        expect(
          labelRect.top,
          greaterThan(stripRect.top),
          reason:
              '$label label top ${labelRect.top} must lie strictly below '
              'the strip clip edge ${stripRect.top}',
        );
        expect(
          labelRect.bottom,
          lessThan(stripRect.bottom),
          reason: '$label label must not clip at the bottom either',
        );
      }
    }

    testWidgets('LP labels at 320px are fully inside the strip bounds', (
      tester,
    ) async {
      setPhone(tester);
      await pumpModule(tester, const LinearProgramPage());
      await showConstraintCard(tester);
      await expectLabelsUnclipped(tester, 'lp');
    });

    testWidgets('IP labels at 320px are fully inside the strip bounds', (
      tester,
    ) async {
      setPhone(tester);
      await pumpModule(tester, const IntegerProgramHomePage());
      await showConstraintCard(tester);
      await expectLabelsUnclipped(tester, 'mip');
    });

    testWidgets('labels stay unclipped at 200% text scale', (tester) async {
      setPhone(tester, scale: 2.0, height: 1200);
      await pumpModule(tester, const LinearProgramPage());
      await showConstraintCard(tester);
      await expectLabelsUnclipped(tester, 'lp');
      expect(tester.takeException(), isNull);
    });

    testWidgets('labels stay unclipped in dark mode', (tester) async {
      setPhone(tester);
      await pumpModule(
        tester,
        const LinearProgramPage(),
        theme: AppTheme.dark(),
      );
      await showConstraintCard(tester);
      await expectLabelsUnclipped(tester, 'lp');
      expect(tester.takeException(), isNull);
    });
  });
}
