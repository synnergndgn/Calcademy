import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local auth repository defaults to signed out', () {
    final repository = LocalAuthRepository();
    expect(repository.status, AuthStatus.signedOut);
    expect(repository.currentUser, isNull);
  });

  test('local auth repository accepts a mock signed-in session', () {
    final repository = LocalAuthRepository();
    const user = AppUser(id: 'test-user', email: 'test@example.invalid');
    repository.setSession(status: AuthStatus.signedIn, user: user);
    expect(repository.status, AuthStatus.signedIn);
    expect(repository.currentUser, same(user));
  });
}
