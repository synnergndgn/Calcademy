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

  @override
  AuthStatus get status => _status;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  void setSession({required AuthStatus status, AppUser? user}) {
    _status = status;
    _currentUser = status == AuthStatus.signedIn ? user : null;
  }
}
