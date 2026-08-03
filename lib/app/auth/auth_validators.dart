abstract final class AuthValidators {
  static bool isValidEmail(String value) {
    final email = value.trim();
    final separator = email.indexOf('@');
    return separator > 0 &&
        separator < email.length - 3 &&
        email.indexOf('.', separator) > separator + 1;
  }

  static bool isValidPassword(String value) => value.length >= 8;

  static bool passwordsMatch(String password, String confirmation) =>
      password == confirmation;
}
