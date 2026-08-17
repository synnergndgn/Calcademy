import 'package:calcademy/app/router.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:calcademy/features/account/presentation/sign_in_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('/assistant opens the local Assistant page', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/assistant');
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
    expect(find.byType(AiAssistantPage), findsOneWidget);
    expect(find.byKey(const Key('ai-assistant-input')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('premium-sign-in-placeholder')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });

  test('Assistant localization keys have English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'aiAssistantTitle',
      'aiAssistantSubtitle',
      'aiAssistantScopeNotice',
      'aiAssistantInputHint',
      'aiAssistantSend',
      'aiAssistantUnsupported',
      'aiAssistantOutOfScope',
      'aiAssistantOpenTool',
      'aiAssistantOpenFormula',
      'aiAssistantSuggestedTool',
      'aiAssistantSuggestedFormula',
      'aiAssistantLocalModeNotice',
      'aiAssistantFinancialDisclaimer',
      'aiAssistantEmptyInput',
      'aiAssistantCharacterLimit',
      'aiAssistantExamples',
      'aiAssistantComingSoonCamera',
      'aiAssistantComingSoonGemini',
    ];
    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
  });
}
