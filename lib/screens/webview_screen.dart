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
  bool _isRedirecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소셜 로그인'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Opacity(
        opacity: _isRedirecting ? 0.0 : 1.0, // redirecting 여부로 해당 화면을 보여줄지 말지 결정
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onLoadStart: (controller, url) {
            if (url != null && url.toString().contains("callback")) {
              setState(() {
                _isRedirecting = true;
              });
            }
          },
          onLoadStop: (controller, url) async {
            if (_isRedirecting && url != null) {
              // Get the page body
              final body = await controller.evaluateJavascript(source: "document.body.innerText");
              if (body != null) {
                try {
                  // The body is expected to be a JSON string, so we parse it.
                  final jsonResponse = jsonDecode(body);
                  if (jsonResponse is Map && jsonResponse.containsKey('access_token')) {
                    final token = jsonResponse['access_token'];

                    if (mounted) Navigator.pop(context, token);
                  }
                } catch (e) {
                  // Could not parse JSON, ignore. This happens on the initial login page.
                  debugPrint('Error parsing JSON from webview: $e');

                  if (mounted) Navigator.pop(context, null);
                }
              }
            }
          },
        ),
      )
    );
  }
}
