import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _sessionKey = 'supabase_session';

  // Save session token
  static Future<void> saveSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, token);
  }

  // Retrieve session token
  static Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  // Clear session token
  static Future<void> clearSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
