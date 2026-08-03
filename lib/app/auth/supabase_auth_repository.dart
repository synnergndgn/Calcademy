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
  bool get supportsAccountDeletion => false;

  @override
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return _mapUser(response.user);
  }

  @override
  Future<AppUser?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return _mapUser(response.user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> requestAccountDeletion() async {
    // TODO(auth-backend): Invoke an authenticated, rate-limited Edge Function
    // after it can remove all related user data and the Auth user atomically.
    throw UnsupportedError('Secure account deletion backend is not available.');
  }

  @override
  Future<void> deleteAccount() async {
    // Auth user deletion requires privileged server-side authorization. Never
    // perform that administrative operation from a public mobile client.
    throw UnsupportedError('Secure account deletion backend is not available.');
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
