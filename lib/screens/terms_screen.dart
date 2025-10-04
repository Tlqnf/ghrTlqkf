import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  final String title;
  final String content;

  const TermsScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: Container(color: Theme.of(context).colorScheme.surface),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(content),
        ),
      )
    );
  }
}
