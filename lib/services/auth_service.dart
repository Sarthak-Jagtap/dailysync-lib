import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _isLoggedInKey = 'isLoggedIn';
  static const _userNameKey = 'userName';

  // Checks local login state (for splash screen/auto-login)
  Future<bool> checkLocalLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Use Firebase auth state if available, otherwise check local flag
    return _auth.currentUser != null || (prefs.getBool(_isLoggedInKey) ?? false);
  }

  // Simulates saving user session/details locally after Firebase login
  Future<void> saveLocalAuthDetails(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userNameKey, name);
  }

  // Clears local and Firebase login state
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userNameKey);
    await _auth.signOut();
  }
  
  // Optional: Retrieves local user name for greeting
  Future<String?> getUserName() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(_userNameKey);
  }
}
