import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_validators.dart';
import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local auth repository defaults to signed out', () {
    final repository = LocalAuthRepository();
    expect(repository.status, AuthStatus.signedOut);
    expect(repository.currentUser, isNull);
  });

  test('local auth repository accepts a mock signed-in session', () async {
    final repository = LocalAuthRepository();
    addTearDown(repository.dispose);
    const user = AppUser(id: 'test-user', email: 'test@example.invalid');
    repository.setSession(status: AuthStatus.signedIn, user: user);
    expect(repository.status, AuthStatus.signedIn);
    expect(repository.currentUser, same(user));

    await repository.signOut();
    expect(repository.status, AuthStatus.signedOut);
    expect(repository.currentUser, isNull);
  });

  test('auth state stream publishes session updates', () async {
    final repository = LocalAuthRepository();
    addTearDown(repository.dispose);
    final updates = repository.authStateChanges.take(2).toList();

    repository.setSession(
      status: AuthStatus.signedIn,
      user: const AppUser(id: 'stream-user', email: 'stream@example.com'),
    );
    await repository.signOut();

    expect(await updates, [isA<AppUser>(), isNull]);
  });

  test('local repository supports mock sign in and sign out', () async {
    final repository = LocalAuthRepository();
    addTearDown(repository.dispose);

    final user = await repository.signInWithEmailPassword(
      'student@example.com',
      'password123',
    );
    expect(user?.email, 'student@example.com');
    expect(repository.status, AuthStatus.signedIn);

    await repository.signOut();
    expect(repository.status, AuthStatus.signedOut);
  });

  test('missing config selects local signed-out repository', () {
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    expect(AppConfig.isSupabaseConfigured, isFalse);
    expect(container.read(isAuthConfiguredProvider), isFalse);
    expect(container.read(authRepositoryProvider), isA<LocalAuthRepository>());
    expect(container.read(authRepositoryProvider).status, AuthStatus.signedOut);
  });

  test('mocked dart-define values pass Supabase config parsing', () {
    expect(
      AppConfig.isValidSupabaseConfiguration(
        url: 'https://staging-project.supabase.co',
        publicKey: 'public-test-key',
      ),
      isTrue,
    );
    expect(
      AppConfig.isValidSupabaseConfiguration(
        url: 'http://staging-project.supabase.co',
        publicKey: 'public-test-key',
      ),
      isFalse,
    );
  });

  test('auth validators reject invalid sign in and password mismatch', () {
    expect(AuthValidators.isValidEmail('student@example.com'), isTrue);
    expect(AuthValidators.isValidEmail('student-at-example.com'), isFalse);
    expect(AuthValidators.isValidPassword('12345678'), isTrue);
    expect(AuthValidators.isValidPassword('short'), isFalse);
    expect(AuthValidators.passwordsMatch('password', 'password'), isTrue);
    expect(AuthValidators.passwordsMatch('password', 'different'), isFalse);
  });

  test('repository interface includes secure deletion boundary', () {
    final AuthRepository repository = LocalAuthRepository();
    addTearDown((repository as LocalAuthRepository).dispose);
    expect(repository.supportsAccountDeletion, isFalse);
    expect(repository.requestAccountDeletion(), throwsUnsupportedError);
    expect(repository.deleteAccount(), throwsUnsupportedError);
  });

  test('successful mock deletion clears the signed-in session', () async {
    final repository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'delete-me', email: 'me@example.com'),
      supportsAccountDeletion: true,
    );
    addTearDown(repository.dispose);

    await repository.requestAccountDeletion();

    expect(repository.status, AuthStatus.signedOut);
    expect(repository.currentUser, isNull);
  });

  test('signed-out mock user cannot delete an account', () async {
    final repository = LocalAuthRepository(supportsAccountDeletion: true);
    addTearDown(repository.dispose);

    await expectLater(
      repository.requestAccountDeletion(),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.messageKey,
          'messageKey',
          'signInRequired',
        ),
      ),
    );
  });

  test('mock deletion failure stays signed in and remains safe', () async {
    final repository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'keep-me', email: 'me@example.com'),
      supportsAccountDeletion: true,
      accountDeletionFailure: const AuthFailure('accountDeletionFailed'),
    );
    addTearDown(repository.dispose);

    await expectLater(
      repository.requestAccountDeletion(),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.messageKey,
          'messageKey',
          'accountDeletionFailed',
        ),
      ),
    );
    expect(repository.status, AuthStatus.signedIn);
  });
}
