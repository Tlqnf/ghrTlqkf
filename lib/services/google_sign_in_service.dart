import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// 초기화 및 lightweight 인증
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    _googleSignIn
        .initialize(clientId: clientId, serverClientId: serverClientId)
        .then((_) {
      // 인증 이벤트 스트림 구독
      _googleSignIn.authenticationEvents
          .listen(_handleAuthenticationEvent)
          .onError(_handleAuthenticationError);

      // 경량 인증 시도
      _googleSignIn.attemptLightweightAuthentication();
    });
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    debugPrint('Authentication Event: $event');
  }

  void _handleAuthenticationError(Object error) {
    debugPrint('Authentication Error: $error');
  }

  /// 사용자 버튼 클릭 시 로그인
  Future<GoogleSignInAccount?> signIn() async {
    if (_googleSignIn.supportsAuthenticate()) {
      try {
        return await _googleSignIn.authenticate();
      } catch (e) {
        debugPrint('Sign-in failed: $e');
        return null;
      }
    } else if (kIsWeb) {
      debugPrint('Web platform: render button for user login');
      return null;
    } else {
      debugPrint('Platform does not support direct authenticate');
      return null;
    }
  }

  /// 특정 scope 요청 (null-safety 적용)
  Future<GoogleSignInClientAuthorization?> requestScopes(
      GoogleSignInAccount user, List<String> scopes) async {
    final authorization = await user.authorizationClient
        .authorizationForScopes(scopes);

    if (authorization == null) {
      return await user.authorizationClient.authorizeScopes(scopes);
    }

    return authorization;

  }

  /// 서버용 인증 코드 요청 (null-safety 적용)
  Future<GoogleSignInServerAuthorization?> getServerAuthCode(
      GoogleSignInAccount user, List<String> scopes) async {
    final serverAuth =
    await user.authorizationClient.authorizeServer(scopes);
    return serverAuth;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
