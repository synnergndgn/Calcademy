import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGateState {
  const AuthGateState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(),
);

final authGateControllerProvider =
    NotifierProvider<AuthGateController, AuthGateState>(AuthGateController.new);

class AuthGateController extends Notifier<AuthGateState> {
  @override
  AuthGateState build() {
    final repository = ref.watch(authRepositoryProvider);
    return AuthGateState(
      status: repository.status,
      user: repository.currentUser,
    );
  }

  void setMockSession({required AuthStatus status, AppUser? user}) {
    ref.read(authRepositoryProvider).setSession(status: status, user: user);
    state = AuthGateState(
      status: status,
      user: status == AuthStatus.signedIn ? user : null,
    );
  }
}
