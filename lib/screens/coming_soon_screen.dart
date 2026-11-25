import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen(
      {super.key,
      required this.title,
      required this.emoji,
      required this.text});
  final String title;
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      ),
    );
  }
}
