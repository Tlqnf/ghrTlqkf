import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedal/api/user_api_service.dart';

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
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    try {
      bool? needsProfile = await UserApiService.checkUserProfile(token);
      if (needsProfile == true) {
        _authState = AuthState.needsProfileSetup;
      } else {
        _authState = AuthState.loggedIn;
      }
    } catch (e) {
      await logout();
    }
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
      // Here you might want to add token validation logic
      // For now, we'll just log in with the stored token.
      await login(extractedToken);
    }
  }
}
