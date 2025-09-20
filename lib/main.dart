import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  await FlutterNaverMap().init(
      clientId: dotenv.env["CLIENT_ID"],
      onAuthFailed: (ex) {
        switch (ex) {
          case NQuotaExceededException(:final message):
            debugPrint("사용량 초과 (message: $message)");
            break;
          case NUnauthorizedClientException() ||
              NClientUnspecifiedException() ||
              NAnotherAuthFailedException():
            debugPrint("인증 실패: $ex");
            break;
        }
      });
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const PedalApp(),
    ),
  );
}

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

// 2. 팔레트 색상으로 ColorScheme 정의 (Top-level)
final colorScheme = ColorScheme(
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

// 3. 커스텀 색상을 ThemeExtension에 정의 (Top-level)
const appColors = AppColors(
  success: Color(0xFF34C759),
  info: Color(0xFF0A84FF),
  warning: Color(0xFFFF9500),
  highlight: Color(0xFFFF6B00),
);

class PedalApp extends StatelessWidget {
  const PedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        extensions: const [appColors],
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: colorScheme.onBackground),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: colorScheme.onSurface,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colorScheme.onSurface,
        ),
      ),
      home: FutureBuilder(
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (ctx, snapshot) {
          // While waiting for auto-login to complete, show a loading screen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              switch (auth.authState) {
                case AuthState.loggedIn:
                  return MainNavigationScreen();
                case AuthState.needsProfileSetup:
                  return ProfileSetupPage(
                    token: auth.token!,
                    onSetupComplete: () {
                      auth.completeProfileSetup();
                    },
                  );
                case AuthState.loggedOut:
                  return LoginPage(
                    onLogin: (token) {
                      Provider.of<AuthProvider>(context, listen: false).login(token);
                    },
                  );
                case AuthState.loading:
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            },
          );
        },
      ),
    );
  }
}