import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:pedal/config/firebase_options.dart';
import 'package:pedal/services/fcm_service.dart';
import 'package:provider/provider.dart';

// ThemeExtension을 사용한 AppColors 정의
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.background,
    required this.subBg,
    required this.text,
    required this.subText,
    required this.stroke,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
    required this.highlight,
  });

  final Color? primary;    // 메인 컬러
  final Color? background; // 이전 background
  final Color? subBg;      // 이전 surface (Sub Bg)
  final Color? text;       // 이전 onSurface (Text)
  final Color? subText;    // 이전 onSurfaceVariant (Sub Text)
  final Color? stroke;     // 이전 outline (Stroke)
  final Color? success;    // Success (성공 상태)
  final Color? info;       // 이전 secondary (정보)
  final Color? warning;    // Warning (경고 상태)
  final Color? error;      // Error (오류 상태)
  final Color? highlight;  // 이전 primary (강조, 메인 레드)

  // 기본 'light' 테마 색상을 static 상수로 정의합니다.
  static const light = AppColors(
    primary: Color(0xFFFF3B30),
    background: Color(0xFFFFFFFF),
    subBg: Color(0xFFF7F7F7),
    text: Color(0xFF272727),
    subText: Color(0xFF8E8E93),
    stroke: Color(0xFF8E8E93),
    success: Color(0xFF34C759), // 시스템 그린 색상
    info: Color(0xFF0A84FF),
    warning: Color(0xFFFFCC00), // 시스템 옐로우 색상
    error: Color(0xFFE70C00),
    highlight: Color(0xFFFF6B00),
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
      primary: primary,
      background: background ?? this.background,
      subBg: subBg ?? this.subBg,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      stroke: stroke ?? this.stroke,
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      error: error,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t),
      background: Color.lerp(background, other.background, t),
      subBg: Color.lerp(subBg, other.subBg, t),
      text: Color.lerp(text, other.text, t),
      subText: Color.lerp(subText, other.subText, t),
      stroke: Color.lerp(stroke, other.stroke, t),
      success: Color.lerp(success, other.success, t),
      info: Color.lerp(info, other.info, t),
      warning: Color.lerp(warning, other.warning, t),
      error: Color.lerp(error, other.error, t),
      highlight: Color.lerp(highlight, other.highlight, t),
    );
  }
}

// AppColors.light 값을 기반으로 ColorScheme 정의
final colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.light.primary!,
  onPrimary: Colors.black,
  secondary: AppColors.light.info!,
  onSecondary: Colors.white,
  error: AppColors.light.error!,
  onError: Colors.white,
  background: Colors.white,
  surface: AppColors.light.background!,
  onSurface: AppColors.light.text!,
  outline: AppColors.light.stroke!,
  onSurfaceVariant: AppColors.light.subText!,
);

// =====================
// 1️⃣ FCM background handler (Top-level)
// =====================
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // 필요 시 background 처리
}

// =====================
// 2️⃣ main()
// =====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kakao SDK 초기화
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']);

  // FCM background handler 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM 초기화
  await FCMService().initialize();

  // Naver Map 초기화
  await FlutterNaverMap().init(
    clientId: dotenv.env["CLIENT_ID"],
    onAuthFailed: (ex) {
      debugPrint("Naver Map Auth failed: $ex");
    },
  );

  // Google Sign-In 초기화 (모바일 앱 기준 clientId->android / serverClientId->webClient)
  await GoogleSignIn.instance.initialize(
    clientId: dotenv.env["GOOGLE_CLIENT_ID"],
    serverClientId: dotenv.env["GOOGLE_SERVER_CLIENT_ID"], // 서버 검증용
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const PedalApp(),
    ),
  );
}

// =====================
// 3️⃣ PedalApp
// =====================
class PedalApp extends StatefulWidget {
  const PedalApp({super.key});

  @override
  State<PedalApp> createState() => _PedalAppState();
}

class _PedalAppState extends State<PedalApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        extensions: <ThemeExtension<dynamic>>[AppColors.light],
      ),
      home: FutureBuilder(
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              switch (auth.authState) {
                case AuthState.loading:
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                case AuthState.loggedIn:
                  return MainNavigationScreen();
                case AuthState.needsProfileSetup:
                  return ProfileSetupPage(
                    token: auth.token!,
                    onSetupComplete: () => auth.completeProfileSetup(),
                  );
                case AuthState.loggedOut:
                  return LoginScreen();
              }
            },
          );
        },
      ),
    );
  }
}