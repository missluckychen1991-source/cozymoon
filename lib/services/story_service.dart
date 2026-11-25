import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_ready.dart';
import '../content/stories.dart';

const storySettings = [
  'Rainy Café',
  'Night Train',
  'Seaside Town',
  'Bookshop',
  'Mountain Cabin',
  'Kyoto Garden'
];
const storyVibes = [
  'Sweet Romance',
  'Cozy Friendship',
  'Funny Mishap',
  'Sleepy & Slow',
  'Solo Adventure'
];

/// "Write me a 2-minute cozy story" using the friend's AI, with a library
/// story as the offline fallback.
class StoryService {
  StoryService({Random? random}) : _random = random ?? Random();
  final Random _random;

  Future<Story> write(String setting, String vibe) async {
    if (firebaseReady) {
      try {
        final res = await FirebaseFunctions.instance
            .httpsCallable('cozyStory',
                options:
                    HttpsCallableOptions(timeout: const Duration(seconds: 30)))
            .call<Map<String, dynamic>>({'setting': setting, 'vibe': vibe});
        final body = (res.data['body'] as String?)?.trim() ?? '';
        if (body.isNotEmpty) {
          return Story(
            title: (res.data['title'] as String?)?.trim().isNotEmpty == true
                ? res.data['title'] as String
                : '$setting, $vibe',
            tag: _tagFor(vibe),
            minutes: 2,
            body: body,
          );
        }
      } catch (_) {/* use the library instead */}
    }
    final matches = stories.where((s) => s.tag == _tagFor(vibe)).toList();
    final pool = matches.isEmpty ? stories : matches;
    return pool[_random.nextInt(pool.length)];
  }

  static StoryTag _tagFor(String vibe) => switch (vibe) {
        'Sweet Romance' => StoryTag.romance,
        'Funny Mishap' => StoryTag.funny,
        'Sleepy & Slow' => StoryTag.sleepy,
        _ => StoryTag.sliceOfLife,
      };
}
