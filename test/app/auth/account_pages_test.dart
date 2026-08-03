import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/account/presentation/account_page.dart';
import 'package:calcademy/features/account/presentation/create_account_page.dart';
import 'package:calcademy/features/account/presentation/delete_account_page.dart';
import 'package:calcademy/features/account/presentation/sign_in_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('/account opens with signed-out no-login actions', (
    tester,
  ) async {
    final router = _router('/account');
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Continue without account'), findsOneWidget);
    expect(
      find.text('Core tools are available without an account.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('auth-not-configured-notice')), findsOneWidget);
  });

  testWidgets('/sign-in renders disabled config-missing state', (tester) async {
    final router = _router('/sign-in');
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.text('Auth is not configured yet'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('sign-in-submit')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('/create-account renders disabled config-missing state', (
    tester,
  ) async {
    final router = _router('/create-account');
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byType(CreateAccountPage), findsOneWidget);
    expect(find.textContaining('privacy policy'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('create-account-submit')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('sign in validates email and password', (tester) async {
    final router = _router('/sign-in');
    addTearDown(router.dispose);
    final repository = LocalAuthRepository();
    addTearDown(repository.dispose);
    await _pump(tester, router, repository: repository, configured: true);

    await tester.enterText(find.byKey(const Key('sign-in-email')), 'invalid');
    await tester.enterText(find.byKey(const Key('sign-in-password')), 'short');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must contain at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('create account rejects password mismatch', (tester) async {
    final router = _router('/create-account');
    addTearDown(router.dispose);
    final repository = LocalAuthRepository();
    addTearDown(repository.dispose);
    await _pump(tester, router, repository: repository, configured: true);

    await tester.enterText(
      find.byKey(const Key('create-account-email')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('create-account-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('create-account-confirm-password')),
      'different123',
    );
    await tester.tap(find.byKey(const Key('create-account-submit')));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('/account/delete explains secure backend requirement', (
    tester,
  ) async {
    final router = _router('/account/delete');
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byType(DeleteAccountPage), findsOneWidget);
    expect(find.text('This action cannot be undone'), findsOneWidget);
    expect(
      find.byKey(const Key('account-deletion-backend-notice')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('request-account-deletion-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('signed-in mock user renders account controls', (tester) async {
    final router = _router('/account');
    addTearDown(router.dispose);
    final repository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(
        id: 'student-id',
        email: 'student@example.com',
      ),
    );
    addTearDown(repository.dispose);
    await _pump(tester, router, repository: repository, configured: true);

    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.byKey(const Key('account-sign-out-button')), findsOneWidget);
    expect(find.byKey(const Key('account-delete-button')), findsOneWidget);
  });

  test('Account localization keys have English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'account',
      'signIn',
      'createAccount',
      'signOut',
      'continueWithoutAccount',
      'coreToolsNoAccount',
      'email',
      'password',
      'confirmPassword',
      'forgotPassword',
      'resetPassword',
      'accountDeletion',
      'deleteAccount',
      'requestAccountDeletion',
      'thisActionCannotBeUndone',
      'authNotConfigured',
      'supabaseNotConfigured',
      'accountFeaturesComingSoon',
      'premiumRequiresAccount',
      'manageSubscription',
      'signedInAs',
      'signedOut',
    ];
    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
  });
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
    GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
    GoRoute(
      path: '/create-account',
      builder: (_, _) => const CreateAccountPage(),
    ),
    GoRoute(
      path: '/account/delete',
      builder: (_, _) => const DeleteAccountPage(),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  AuthRepository? repository,
  bool configured = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          authRepositoryProvider.overrideWithValue(repository),
        isAuthConfiguredProvider.overrideWithValue(configured),
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
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
