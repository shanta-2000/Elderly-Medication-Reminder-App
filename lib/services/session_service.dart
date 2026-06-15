import 'package:shared_preferences/shared_preferences.dart';

class SavedLogin {
  const SavedLogin({
    required this.role,
    required this.userId,
    required this.password,
  });

  final String role;
  final String userId;
  final String password;
}

class SessionService {
  static const String roleCaregiver = 'caregiver';
  static const String rolePatient = 'patient';

  static const String _roleKey = 'saved_role';
  static const String _userIdKey = 'saved_user_id';
  static const String _passwordKey = 'saved_password';

  static Future<void> saveLogin({
    required String role,
    required String userId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_roleKey, role);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_passwordKey, password);
  }

  static Future<SavedLogin?> getSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString(_roleKey);
    final userId = prefs.getString(_userIdKey);
    final password = prefs.getString(_passwordKey);

    if (role == null || userId == null || password == null) {
      return null;
    }

    if (role.isEmpty || userId.isEmpty || password.isEmpty) {
      return null;
    }

    return SavedLogin(
      role: role,
      userId: userId,
      password: password,
    );
  }

  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_passwordKey);
  }
}