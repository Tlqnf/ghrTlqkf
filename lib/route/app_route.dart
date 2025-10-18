import 'package:flutter/material.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';

class AppRoute {
  static const String onBoarding = "/on-boarding";
  static const String login = "/login";
  static const String profile = "/profile";
  static const String main = "/main";

  static Map<String, WidgetBuilder> routes = {
    main: (context) => const MainNavigationScreen(),
    login: (context) => const LoginScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) =>
              ProfileSetupScreen(
                onSetupComplete: args?['onSetupComplete'],
                token: args?['token'],
              ),
        );
      default:
        return MaterialPageRoute(
          builder: (context) =>
          const Scaffold(
            body: Center(child: Text("Route not found")),
          ),
        );
    }
  }
}