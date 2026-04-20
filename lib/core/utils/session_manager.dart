import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _loginTimeKey = 'login_time';
  static const String _authTokenKey = 'auth_token';
  static const int _sessionDurationHours = 48;
  static const _sessionDuration = Duration(hours: _sessionDurationHours);

  /// Saves the current time as the login time and optionally an auth token.
  static Future<void> saveSession({String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
    if (token != null) {
      await prefs.setString(_authTokenKey, token);
    }
  }

  /// Checks if the session is still valid (less than 48 hours old).
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimeString = prefs.getString(_loginTimeKey);

    if (loginTimeString == null) return false;

    try {
      final loginTime = DateTime.parse(loginTimeString);
      final expirationTime = loginTime.add(_sessionDuration);
      return DateTime.now().isBefore(expirationTime);
    } catch (e) {
      return false; // If parsing fails, consider session invalid
    }
  }

  /// Retrieves the saved auth token.
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Clears the saved session data.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_authTokenKey);
  }

  /// Restores/refreshes the session timestamp (useful when app cache is cleared but user is still authenticated)
  static Future<void> restoreSession({String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
    if (token != null) {
      await prefs.setString(_authTokenKey, token);
    }
  }
}
