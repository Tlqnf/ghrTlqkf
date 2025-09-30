import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedal/api/user_api.dart';

enum AuthState { loggedOut, needsProfileSetup, loggedIn, loading }

class AuthProvider with ChangeNotifier {
  String? _token;
  AuthState _authState = AuthState.loggedOut;

  String? get token => _token;
  AuthState get authState => _authState;
  bool get isLoggedIn => _authState == AuthState.loggedIn || _authState == AuthState.needsProfileSetup;

  Future<void> login(String token) async {
    _token = token;
    _authState = AuthState.loading;
    debugPrint('AuthProvider: authState set to loading. Token: $_token');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    try {
      debugPrint('AuthProvider: Calling UserApi.checkUserProfile...');
      bool? needsProfile = await UserApi.checkUserProfile(token);
      debugPrint('AuthProvider: UserApi.checkUserProfile returned needsProfile: $needsProfile');
      if (needsProfile == true) {
        _authState = AuthState.needsProfileSetup;
        debugPrint('AuthProvider: authState set to needsProfileSetup');
      } else {
        _authState = AuthState.loggedIn;
        debugPrint('AuthProvider: authState set to loggedIn');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error during checkUserProfile: $e');
      await logout();
      debugPrint('AuthProvider: Logged out due to error.');
    }
    debugPrint('AuthProvider: Notifying listeners with final state: $_authState');
    notifyListeners();
  }

  void completeProfileSetup() {
    if (_authState == AuthState.needsProfileSetup) {
      _authState = AuthState.loggedIn;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _authState = AuthState.loggedOut;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return;
    }
    final extractedToken = prefs.getString('token');
    if (extractedToken != null) {
      await login(extractedToken);
    }
  }
}
