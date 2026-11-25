import 'package:flutter/material.dart';

import '../content/stories.dart';

class StoryReader extends StatelessWidget {
  const StoryReader({super.key, required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('${story.tag.emoji} ${story.tag.label}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text(story.title,
              key: const Key('story-title'), style: t.headlineSmall),
          const SizedBox(height: 4),
          Text('${story.minutes} min read', style: t.bodySmall),
          const SizedBox(height: 20),
          Text(story.body, style: t.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 32),
          const Center(child: Text('🌙 The end. Stay as long as you like.')),
        ],
      ),
    );
  }
}
