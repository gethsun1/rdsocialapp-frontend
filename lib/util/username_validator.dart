class UsernameValidator {
  UsernameValidator._();

  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_.]{3,20}$');
  static final RegExp _emailPattern =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', caseSensitive: false);

  static bool isValid(String value) {
    final username = value.trim();
    return _usernamePattern.hasMatch(username) &&
        !_emailPattern.hasMatch(username);
  }

  static String normalize(String value) => value.trim().toLowerCase();
}
