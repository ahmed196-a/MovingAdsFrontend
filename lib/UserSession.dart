import 'package:shared_preferences/shared_preferences.dart';

class UserSession {

  static Future<void> saveUser(int? id, String name, String role) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id!);
    await prefs.setString('username', name);
    await prefs.setString('role', role);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
