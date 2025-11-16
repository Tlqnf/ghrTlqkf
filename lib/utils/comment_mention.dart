import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';

Future<List<TextSpan>> buildMentionTextSpans(String text, String? token) async {
  final List<TextSpan> spans = [];
  final RegExp mentionRegex = RegExp(r'@([ㄱ-ㅎ가-힣a-zA-Z0-9_]+)');
  int lastMatchEnd = 0;

  for (final Match match in mentionRegex.allMatches(text)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
    }

    final String username = match.group(1)!;
    bool isValid = false;

    if (token != null) {
      try {
        isValid = await UserApi.checkUserMention(username, token) ?? false;
      } catch (_) {
        isValid = false;
      }
    }

    if (isValid) {
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      spans.add(TextSpan(text: match.group(0)));
    }

    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastMatchEnd)));
  }

  return spans;
}
