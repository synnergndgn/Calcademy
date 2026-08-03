import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_status.dart';

abstract interface class AuthRepository {
  AuthStatus get status;
  AppUser? get currentUser;

  void setSession({required AuthStatus status, AppUser? user});
}
