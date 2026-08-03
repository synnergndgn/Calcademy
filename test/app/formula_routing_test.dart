import 'package:calcademy/app/router.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/formula_library/presentation/formula_detail_page.dart';
import 'package:calcademy/features/formula_library/presentation/formula_library_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('/formulas and formula detail routes open', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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
          routerConfig: appRouter,
        ),
      ),
    );

    appRouter.go('/formulas');
    await tester.pumpAndSettle();
    expect(find.byType(FormulaLibraryPage), findsOneWidget);

    appRouter.go('/formulas/quadratic-formula');
    await tester.pumpAndSettle();
    expect(find.byType(FormulaDetailPage), findsOneWidget);
    expect(find.text('Quadratic Formula'), findsWidgets);

    appRouter.go('/formulas/not-a-formula');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('formula-not-found')), findsOneWidget);
  });
}
