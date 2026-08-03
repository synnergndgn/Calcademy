import 'dart:async';

import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    AuthStatus initialStatus = AuthStatus.signedOut,
    AppUser? initialUser,
  }) : _status = initialStatus,
       _currentUser = initialUser;

  AuthStatus _status;
  AppUser? _currentUser;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  AuthStatus get status => _status;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _changes.stream;

  @override
  bool get supportsAccountDeletion => false;

  @override
  Future<AppUser?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final user = AppUser(id: 'local-${email.hashCode}', email: email.trim());
    setSession(status: AuthStatus.signedIn, user: user);
    return user;
  }

  @override
  Future<AppUser?> signUpWithEmailPassword(String email, String password) =>
      signInWithEmailPassword(email, password);

  @override
  Future<void> signOut() async {
    setSession(status: AuthStatus.signedOut);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> requestAccountDeletion() async {
    throw UnsupportedError('Secure account deletion backend is not available.');
  }

  @override
  Future<void> deleteAccount() async {
    throw UnsupportedError('Secure account deletion backend is not available.');
  }

  void setSession({required AuthStatus status, AppUser? user}) {
    _status = status;
    _currentUser = status == AuthStatus.signedIn ? user : null;
    _changes.add(_currentUser);
  }

  Future<void> dispose() => _changes.close();
}
