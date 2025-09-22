import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/api/firebase_message_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/config/firebase_options.dart';
import 'package:pedal/services/fcm_service.dart';
import 'package:provider/provider.dart';

// ThemeExtension을 사용한 AppColors 정의
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.subBg,
    required this.text,
    required this.subText,
    required this.stroke,
    required this.success,
    required this.info,
    required this.warning,
    required this.highlight,
  });

  final Color? background; // 이전 background
  final Color? subBg;      // 이전 surface (Sub Bg)
  final Color? text;       // 이전 onSurface (Text)
  final Color? subText;    // 이전 onSurfaceVariant (Sub Text)
  final Color? stroke;     // 이전 outline (Stroke)
  final Color? success;    // Success (성공 상태)
  final Color? info;       // 이전 secondary (정보)
  final Color? warning;    // Warning (경고 상태)
  final Color? highlight;  // 이전 primary (강조, 메인 레드)

  // 기본 'light' 테마 색상을 static 상수로 정의합니다.
  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    subBg: Color(0xFFF7F7F7),
    text: Color(0xFF272727),
    subText: Color(0xFF8E8E93),
    stroke: Color(0xFF8E8E93),
    success: Color(0xFF34C759), // 시스템 그린 색상
    info: Color(0xFF0A84FF),
    warning: Color(0xFFFFCC00), // 시스템 옐로우 색상
    highlight: Color(0xFFFF3B30),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? subBg,
    Color? text,
    Color? subText,
    Color? stroke,
    Color? success,
    Color? info,
    Color? warning,
    Color? highlight,
  }) {
    return AppColors(
      background: background ?? this.background,
      subBg: subBg ?? this.subBg,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      stroke: stroke ?? this.stroke,
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
      background: Color.lerp(background, other.background, t),
      subBg: Color.lerp(subBg, other.subBg, t),
      text: Color.lerp(text, other.text, t),
      subText: Color.lerp(subText, other.subText, t),
      stroke: Color.lerp(stroke, other.stroke, t),
      success: Color.lerp(success, other.success, t),
      info: Color.lerp(info, other.info, t),
      warning: Color.lerp(warning, other.warning, t),
      highlight: Color.lerp(highlight, other.highlight, t),
    );
  }
}

// AppColors.light 값을 기반으로 ColorScheme 정의
final colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.light.highlight!,
  onPrimary: Colors.white,
  secondary: AppColors.light.info!,
  onSecondary: Colors.white,
  error: const Color(0xFFE70C00), // Error
  onError: Colors.white,
  background: AppColors.light.background!,
  onBackground: AppColors.light.text!,
  surface: AppColors.light.subBg!,
  onSurface: AppColors.light.text!,
  outline: AppColors.light.stroke!,
  onSurfaceVariant: AppColors.light.subText!,
);


void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);

  // firebase 설정
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(FCMService().backgroundMessageHandler);
  await FCMService().initialize(); // Initialize FCM service once at startup

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

class PedalApp extends StatefulWidget {
  const PedalApp({super.key});

  @override
  State<PedalApp> createState() => _PedalAppState();
}

class _PedalAppState extends State<PedalApp> {

  // FCM 토큰 업데이트 로직을 별도 함수로 분리
  Future<void> _updateFcmToken(String token) async {
    try {
      final fcmService = FCMService();
      final fcmToken = await fcmService.getToken();
      if (fcmToken != null) {
        await FcmApiService.updateUserFcmToken(token, fcmToken);
      }
    } catch (e) {
      debugPrint('FCM 토큰 업데이트 오류: $e');
    }
  }

  Future<void> _handleLogin(String token) async {
    Provider.of<AuthProvider>(context, listen: false).login(token);

    try {
      // 1. 사용자 프로필 가져오기
      await UserApiService.fetchUserProfile(token);
      
      // 2. FCM 토큰 업데이트 (분리된 함수 호출)
      await _updateFcmToken(token);

    } catch (e) {
      debugPrint('로그인 프로세스 오류: $e');
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        extensions: const <ThemeExtension<dynamic>>[
          AppColors.light,
        ],
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: colorScheme.onBackground),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: colorScheme.onSurface,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline.withAlpha(128)),
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
                case AuthState.loading:
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                  return LoginScreen(
                    onLogin: _handleLogin
                  );
              }
            },
          );
        },
      ),
    );
  }
}