package com.example.pedal

import android.os.Bundle
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.user.UserApiClient
import io.flutter.embedding.android.FlutterActivity

class KakaoTalkLoginActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 카카오톡으로 로그인
        UserApiClient.instance.loginWithKakaoTalk(this) { token, error ->
            if (error != null) {
                // 로그인 실패
                finish()
            } else if (token != null) {
                // 로그인 성공
                // TODO: 토큰 처리
                finish()
            }
        }
    }
}
