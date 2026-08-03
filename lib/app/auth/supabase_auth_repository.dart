import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthStatus get status =>
      currentUser == null ? AuthStatus.signedOut : AuthStatus.signedIn;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
    (event) => _mapUser(event.session?.user ?? _client.auth.currentUser),
  );

  @override
  bool get supportsAccountDeletion => true;

  @override
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _mapUser(response.user);
    } on AuthException catch (error) {
      throw AuthFailure(_messageKeyFor(error));
    }
  }

  @override
  Future<AppUser?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      // Hosted projects require email confirmation by default. A returned User
      // without a Session is a successful sign-up, but not a signed-in state.
      return response.session == null ? null : _mapUser(response.session!.user);
    } on AuthException catch (error) {
      throw AuthFailure(_messageKeyFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(_messageKeyFor(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw AuthFailure(_messageKeyFor(error));
    }
  }

  @override
  Future<void> requestAccountDeletion() async {
    if (_client.auth.currentSession == null) {
      throw const AuthFailure('signInRequired');
    }
    try {
      final response = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );
      final data = response.data;
      if (response.status < 200 ||
          response.status >= 300 ||
          data is! Map ||
          data['success'] != true) {
        throw const AuthFailure('accountDeletionFailed');
      }
      // The Auth user no longer exists, so clear the persisted client session
      // locally rather than attempting another privileged network operation.
      await _client.auth.signOut(scope: SignOutScope.local);
    } on AuthFailure {
      rethrow;
    } on FunctionException {
      throw const AuthFailure('accountDeletionFailed');
    } on AuthException {
      throw const AuthFailure('accountDeletionFailed');
    } catch (_) {
      throw const AuthFailure('accountDeletionFailed');
    }
  }

  @override
  Future<void> deleteAccount() => requestAccountDeletion();

  String _messageKeyFor(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => 'invalidCredentials',
      'email_not_confirmed' => 'emailNotConfirmed',
      'user_already_exists' || 'email_exists' => 'accountAlreadyExists',
      'weak_password' => 'weakPassword',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => 'tooManyRequests',
      _ => 'authenticationFailed',
    };
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    final displayName = user.userMetadata?['display_name'];
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: displayName is String ? displayName : null,
    );
  }
}
