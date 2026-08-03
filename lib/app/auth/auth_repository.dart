import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_status.dart';

abstract interface class AuthRepository {
  AuthStatus get status;
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;
  bool get supportsAccountDeletion;

  Future<AppUser?> signInWithEmailPassword(String email, String password);
  Future<AppUser?> signUpWithEmailPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> requestAccountDeletion();
  Future<void> deleteAccount();
}
