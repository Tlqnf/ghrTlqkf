import 'package:flutter/material.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';
import 'package:pedal/screens/main_navigation_screen.dart';

// 1. ThemeExtension을 사용하여 커스텀 색상 클래스 정의
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.highlight,
  });

  final Color? success;
  final Color? info;
  final Color? warning;
  final Color? highlight;

  @override
  AppColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? highlight,
  }) {
    return AppColors(
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      success: Color.lerp(success, other.success, t),
      info: Color.lerp(info, other.info, t),
      warning: Color.lerp(warning, other.warning, t),
      highlight: Color.lerp(highlight, other.highlight, t),
    );
  }
}

void main() {
  runApp(const PedalApp());
}

class PedalApp extends StatefulWidget {
  const PedalApp({super.key});

  @override
  State<PedalApp> createState() => _PedalAppState();
}

enum AuthState { loggedOut, needsProfileSetup, loggedIn }

class _PedalAppState extends State<PedalApp> {
  AuthState _authState = AuthState.loggedOut;

  void _onLogin() {
    setState(() {
      _authState = AuthState.needsProfileSetup;
    });
  }

  void _onProfileSetupComplete() {
    setState(() {
      _authState = AuthState.loggedIn;
    });
  }

  // 2. 팔레트 색상으로 ColorScheme 정의
  static final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFFFF3B30), // Main Red
    onPrimary: Colors.white,
    secondary: const Color(0xFF0A84FF), // Info
    onSecondary: Colors.white,
    error: const Color(0xFFE70C00), // Error
    onError: Colors.white,
    background: const Color(0xFFFFFFFF), // Background
    surface: const Color(0xFFF7F7F7), // Sub Bg
    onSurface: const Color(0xFF272727), // Text
    outline: const Color(0xFF8E8E93), // Stroke
    onSurfaceVariant: const Color(0xFF8E8E93), // Sub Text
  );

  // 3. 커스텀 색상을 ThemeExtension에 정의
  static const appColors = AppColors(
    success: Color(0xFF34C759),
    info: Color(0xFF0A84FF),
    warning: Color(0xFFFF9500),
    highlight: Color(0xFFFF6B00),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedal',
      // 4. MaterialApp에 ThemeData 적용
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        extensions: const [appColors],
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: colorScheme.onBackground),
        ),
        // 입력창 포커스 색상 등을 onSurface로 지정
        inputDecorationTheme: InputDecorationTheme(
          focusColor: colorScheme.onSurface,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colorScheme.onSurface,
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_authState) {
      case AuthState.loggedIn:
        return const MainNavigationScreen();
      case AuthState.needsProfileSetup:
        return ProfileSetupPage(onSetupComplete: _onProfileSetupComplete);
      case AuthState.loggedOut:
      return LoginPage(onLogin: _onLogin);
    }
  }
}