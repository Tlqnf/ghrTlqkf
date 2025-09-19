
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소셜 로그인'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onLoadStop: (controller, url) async {
          if (url != null) {
            // Get the page body
            final body = await controller.evaluateJavascript(source: "document.body.innerText");
            if (body != null) {
              try {
                // The body is expected to be a JSON string, so we parse it.
                final jsonResponse = jsonDecode(body);
                if (jsonResponse is Map && jsonResponse.containsKey('access_token')) {
                  final token = jsonResponse['access_token'];
                  Navigator.pop(context, token);
                }
              } catch (e) {
                // Could not parse JSON, ignore. This happens on the initial login page.
                debugPrint('Error parsing JSON from webview: $e');
              }
            }
          }
        },
      ),
    );
  }
}
