import 'package:calcademy/app/navigation_shell.dart';
import 'package:calcademy/app/router.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Saved is a bottom destination and legacy URL redirects to it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/saved');

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
    await tester.pumpAndSettle();

    expect(find.byType(SavedPage), findsOneWidget);
    expect(find.byType(NavigationShell), findsOneWidget);
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigation.destinations, hasLength(4));
    expect(navigation.selectedIndex, 2);
    expect(find.text('Saved'), findsWidgets);

    appRouter.go('/saved-calculations');
    await tester.pumpAndSettle();

    expect(appRouter.routeInformationProvider.value.uri.path, '/saved');
    expect(find.byType(SavedPage), findsOneWidget);
  });
}
