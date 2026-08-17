import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/core/widgets/result_action_bar.dart';
import 'package:calcademy/core/widgets/section_header.dart';
import 'package:calcademy/core/widgets/status_banner.dart';
import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/features/home/presentation/widgets/professional_module_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('professional module card renders its hierarchy', (tester) async {
    await tester.pumpWidget(
      _app(
        const ProfessionalModuleCard(
          module: AcademyModule(
            id: 'test-tool',
            titleKey: 'calculator',
            descriptionKey: 'calculatorDescription',
            icon: Icons.calculate_rounded,
            category: AcademyModuleCategory.mathematics,
            route: '/calculator',
            available: true,
          ),
        ),
      ),
    );

    expect(find.text('Scientific Calculator'), findsOneWidget);
    expect(
      find.text('Evaluate basic and scientific expressions.'),
      findsOneWidget,
    );
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
  });

  testWidgets('compact module action never squeezes Open workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 138,
            child: ProfessionalModuleCard(
              compact: true,
              module: AcademyModule(
                id: 'compact-workspace',
                titleKey: 'formulaLibraryTitle',
                descriptionKey: 'formulaLibrarySubtitle',
                icon: Icons.menu_book_rounded,
                category: AcademyModuleCategory.workspace,
                route: '/formulas',
                available: true,
              ),
            ),
          ),
        ),
      ),
    );

    final action = tester.widget<Text>(find.text('Open'));
    expect(action.maxLines, 1);
    expect(find.text('Open workspace'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared empty, section, and status states render semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SectionHeader(
              title: 'Section',
              subtitle: 'Section details',
              icon: Icons.functions,
            ),
            StatusBanner(
              title: 'Warning',
              message: 'Check this value.',
              tone: StatusBannerTone.warning,
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nothing here',
                body: 'Start a calculation.',
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Section'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Check this value.'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('result action bar keeps copy and save actions responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _app(
        ResultActionBar(
          copyText: '42',
          copyButtonKey: const Key('shared-copy'),
          saveAction: TextButton(
            key: const Key('shared-save'),
            onPressed: () {},
            child: const Text('Save result'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('shared-copy')), findsOneWidget);
    expect(find.byKey(const Key('shared-save')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('shared-copy'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('academic primitives reflow at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudyHeader(
                eyebrow: 'Workspace',
                title: 'A long academic workspace title',
                subtitle: 'Supporting copy remains readable without clipping.',
                formula: 'f(x) → result',
                trailing: FilledButton(
                  onPressed: () {},
                  child: const Text('Open notebook'),
                ),
              ),
              ToolDock(
                items: [
                  for (var index = 0; index < 5; index++)
                    ToolDockItem(
                      key: Key('dock-$index'),
                      icon: Icons.calculate_outlined,
                      label: 'Long tool label $index',
                      onTap: () {},
                    ),
                ],
              ),
              SectionHeader(
                title: 'Responsive section',
                subtitle: 'A subtitle that may occupy multiple lines.',
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: const Text('View all results'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (var index = 0; index < 5; index++) {
      final rect = tester.getRect(find.byKey(Key('dock-$index')));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);
