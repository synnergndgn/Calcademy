import 'dart:async';

import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_repository_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    required this.status,
    required this.isConfigured,
    required this.supportsAccountDeletion,
    this.user,
    this.errorKey,
    this.noticeKey,
  });

  final AuthStatus status;
  final bool isConfigured;
  final bool supportsAccountDeletion;
  final AppUser? user;
  final String? errorKey;
  final String? noticeKey;

  bool get isBusy => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    String? errorKey,
    bool clearError = false,
    String? noticeKey,
    bool clearNotice = false,
  }) => AuthState(
    status: status ?? this.status,
    isConfigured: isConfigured,
    supportsAccountDeletion: supportsAccountDeletion,
    user: clearUser ? null : user ?? this.user,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
    noticeKey: clearNotice ? null : noticeKey ?? this.noticeKey,
  );
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AppUser?>? _subscription;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);
    final configured = ref.watch(isAuthConfiguredProvider);
    _subscription?.cancel();
    _subscription = repository.authStateChanges.listen(_onUserChanged);
    ref.onDispose(() => _subscription?.cancel());
    return AuthState(
      status: repository.status,
      isConfigured: configured,
      supportsAccountDeletion: repository.supportsAccountDeletion,
      user: repository.currentUser,
    );
  }

  Future<bool> signIn(String email, String password) => _runUserAction(
    () => _repository.signInWithEmailPassword(email, password),
    noticeKey: 'signedInSuccessfully',
  );

  Future<bool> signUp(String email, String password) => _runUserAction(
    () => _repository.signUpWithEmailPassword(email, password),
    noticeKey: 'accountCreatedNotice',
  );

  Future<bool> signOut() async {
    if (!state.isConfigured) return false;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearNotice: true,
    );
    try {
      await _repository.signOut();
      state = state.copyWith(
        status: AuthStatus.signedOut,
        clearUser: true,
        noticeKey: 'signedOut',
      );
      return true;
    } catch (_) {
      _setFailure();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (!state.isConfigured) return false;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearNotice: true,
    );
    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(
        status: _repository.status,
        noticeKey: 'passwordResetSent',
      );
      return true;
    } catch (_) {
      _setFailure();
      return false;
    }
  }

  Future<bool> requestAccountDeletion() async {
    if (!state.isConfigured || !state.supportsAccountDeletion) return false;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearNotice: true,
    );
    try {
      await _repository.requestAccountDeletion();
      state = state.copyWith(
        status: _repository.status,
        noticeKey: 'accountDeletionRequested',
      );
      return true;
    } catch (_) {
      _setFailure();
      return false;
    }
  }

  void setMockSession({required AuthStatus status, AppUser? user}) {
    final repository = _repository;
    if (repository is LocalAuthRepository) {
      repository.setSession(status: status, user: user);
    }
    state = state.copyWith(
      status: status,
      user: status == AuthStatus.signedIn ? user : null,
      clearUser: status != AuthStatus.signedIn,
      clearError: true,
      clearNotice: true,
    );
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearNotice: true);
  }

  Future<bool> _runUserAction(
    Future<AppUser?> Function() action, {
    required String noticeKey,
  }) async {
    if (!state.isConfigured) return false;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearNotice: true,
    );
    try {
      final user = await action();
      state = state.copyWith(
        status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
        user: user,
        clearUser: user == null,
        noticeKey: noticeKey,
      );
      return true;
    } catch (_) {
      _setFailure();
      return false;
    }
  }

  void _onUserChanged(AppUser? user) {
    state = state.copyWith(
      status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
      user: user,
      clearUser: user == null,
      clearError: true,
    );
  }

  void _setFailure() {
    state = state.copyWith(
      status: _repository.status,
      user: _repository.currentUser,
      clearUser: _repository.currentUser == null,
      errorKey: 'authenticationFailed',
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
