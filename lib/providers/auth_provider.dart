import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedal/api/user_api.dart';

enum AuthState { loggedOut, needsProfileSetup, loggedIn, loading }

class AuthProvider with ChangeNotifier {
  String? _token;
  AuthState _authState = AuthState.loggedOut;
  bool _hasBackgroundPermission = false;

  String? get token => _token;
  AuthState get authState => _authState;
  bool get isLoggedIn => _authState == AuthState.loggedIn || _authState == AuthState.needsProfileSetup;
  bool get hasBackgroundPermission => _hasBackgroundPermission;

  Future<void> checkBackgroundPermission() async {
    final prefs = await SharedPreferences.getInstance();

    bool hasConsented = prefs.getBool('background_location_consent') ?? false;
    final permission = await Geolocator.checkPermission();
    final hasSystemPermission = (permission == LocationPermission.always);

    if (hasSystemPermission && !hasConsented) {
      await prefs.setBool('background_location_consent', true);
      hasConsented = true;
    }

    if (!hasSystemPermission && hasConsented) {
      await prefs.setBool('background_location_consent', false);
      hasConsented = false;
    }

    _hasBackgroundPermission = hasConsented && hasSystemPermission;

    notifyListeners();
  }


  Future<void> login(String token) async {
    _token = token;
    _authState = AuthState.loading;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    try {
      bool? needsProfile = await UserApi.checkUserProfile(token);
      if (needsProfile == true) {
        _authState = AuthState.needsProfileSetup;
      } else {
        _authState = AuthState.loggedIn;
      }
    } catch (e) {
      debugPrint('AuthProvider: Error during checkUserProfile: $e');
      await logout();
      debugPrint('AuthProvider: Logged out due to error.');
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
    await checkBackgroundPermission(); // 권한 + 동의 기록 최신화
    final prefs = await SharedPreferences.getInstance();
    final extractedToken = prefs.getString('token');
    if (extractedToken != null) {
      await login(extractedToken);
    }
  }
}
