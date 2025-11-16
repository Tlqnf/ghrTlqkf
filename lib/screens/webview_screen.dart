import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // 웹뷰가 로딩 중이면 취소
    if (_controller != null) {
      await _controller!.stopLoading();
    }
    return true; // true를 반환하면 화면이 닫힘
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('소셜 로그인'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: ColoredBox(
          color: Colors.white, // 배경색 흰색으로 덮기
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStop: (controller, url) async {
              if (url != null) {
                try {
                  // 웹페이지 body의 텍스트 가져오기
                  final body = await controller.evaluateJavascript(
                    source: "document.body.innerText",
                  );
                  if (body != null) {
                    final jsonResponse = jsonDecode(body);
                    if (jsonResponse is Map &&
                        jsonResponse.containsKey('access_token')) {
                      final token = jsonResponse['access_token'];

                      // 토큰이 나오면 화면 전체를 흰색으로 덮기
                      await controller.evaluateJavascript(
                        source: """
                        document.documentElement.style.backgroundColor = '#ffffff';
                        document.body.style.display = 'none';
                      """,
                      );

                      // 토큰 반환 후 페이지 종료
                      Navigator.pop(context, token);
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing JSON from webview: $e');
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
