// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/route/app_route.dart';
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
  // ignore: deprecated_member_use
  background: Colors.white,
  surface: AppColors.light.background!,
  onSurface: AppColors.light.text!,
  outline: AppColors.light.stroke!,
  onSurfaceVariant: AppColors.light.subText!,
);

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // 필요 시 background 처리
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // widget binding

  // 환경 변수 설정
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler); // FCM background handler 등록
  await FCMService().initialize(); // FCM

  // Ads 초기화
  MobileAds.instance.initialize();

  // Naver Map 초기화
  await FlutterNaverMap().init(
    clientId: dotenv.env["NAVER_CLIENT_ID"],
    onAuthFailed: (ex) {
      debugPrint("Naver Map Auth failed: $ex");
    },
  );

  // 인앱 로그인 진행
  // Google Sign-In 초기화
  await GoogleSignIn.instance.initialize(
    clientId: dotenv.env["GOOGLE_CLIENT_ID"],// clientId->android
    serverClientId: dotenv.env["GOOGLE_SERVER_CLIENT_ID"], // serverClientId->webClient
  );
  // Kakao SDK 초기화
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const PedalApp(),
    ),
  );
}

class PedalApp extends StatefulWidget {
  const PedalApp({super.key});

  @override
  State<PedalApp> createState() => _PedalAppState();
}

class _PedalAppState extends State<PedalApp> with WidgetsBindingObserver {
  // // Firebase google analytics 설정 추가
  // final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorObservers: [
      //   // 감시자 추가
      //   FirebaseAnalyticsObserver(analytics: analytics),
      // ],
      title: 'Pedal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        extensions: [AppColors.light],
      ),

      routes: AppRoute.routes,
      onGenerateRoute: AppRoute.onGenerateRoute,

      home: FutureBuilder(
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (context, snapshot) {
          // 자동 로그인이 완료될 때까지 로딩 화면을 표시합니다.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 자동 로그인 시도 후, Consumer를 사용하여 인증 상태에 따라 UI를 빌드합니다.
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              switch (auth.authState) {
                case AuthState.loggedIn:
                  debugPrint("로그인 성공");
                  // 메인 화면 위젯 반환
                  return AppRoute.routes[AppRoute.main]!(context);
                case AuthState.needsProfileSetup:
                  // 빌드 후 네비게이션 실행
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoute.profile,
                      arguments: {
                        "onSetupComplete": () => auth.completeProfileSetup(),
                        "token": auth.token,
                      },
                    );
                  });
                  // 내비게이션이 실행될 때까지 로딩 화면을 표시합니다.
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                case AuthState.loggedOut:
                  // 로그인 화면 위젯을 직접 반환합니다.
                  return AppRoute.routes[AppRoute.login]!(context);
                default: // AuthState.loading
                  // 인증 상태가 변경되는 동안 로딩 화면을 표시합니다.
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            },
          );
        },
      ),
    );
  }
}