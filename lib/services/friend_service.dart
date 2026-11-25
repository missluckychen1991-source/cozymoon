import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/cycle.dart';
import '../models/profile.dart';
import 'safety.dart';

class ChatMessage {
  ChatMessage(
      {required this.fromFriend,
      required this.text,
      this.suggestions = const []});
  final bool fromFriend;
  final String text;

  /// Quick action chips such as "Cozy Nook" or "Learn".
  final List<String> suggestions;
}

class FriendReply {
  const FriendReply(
      {required this.text, this.crisis = false, this.suggestions = const []});
  final String text;
  final bool crisis;
  final List<String> suggestions;
}

/// Talks to the AI friend through a Firebase Cloud Function, so the Gemini
/// API key lives on the server and never in the app. When Firebase is not set
/// up or the call fails, the friend answers with a warm offline message.
class FriendService {
  FriendService({this.dailyLimit = 20, Random? random})
      : _random = random ?? Random();

  final int dailyLimit;
  final Random _random;
  int _usedToday = 0;
  DateTime _day = DateTime.now();

  static bool get firebaseReady => Firebase.apps.isNotEmpty;

  Future<FriendReply> reply({
    required String message,
    required List<ChatMessage> history,
    required Profile profile,
    required CycleStatus cycle,
  }) async {
    if (Safety.needsCrisisSupport(message)) {
      return const FriendReply(
        crisis: true,
        text:
            "I'm really glad you told me. You deserve real support right now, "
            'more than I can give as an app. Please reach out to someone who can '
            "be with you. I'm still here, and we can keep talking.",
      );
    }

    final suggestions = _suggestionsFor(profile, cycle);

    if (!_withinLimit()) {
      return FriendReply(
        text:
            "I've talked so much today my teacup is empty ☕. Let's pick this up "
            'tomorrow. Meanwhile, the Cozy Nook is open all night.',
        suggestions: suggestions,
      );
    }

    if (!firebaseReady) {
      return FriendReply(text: _offline(profile), suggestions: suggestions);
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'friendChat',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );
      final recent =
          history.length > 12 ? history.sublist(history.length - 12) : history;
      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
        'vibe': profile.vibe.name,
        'nickname': profile.nickname,
        'mode': cycle.mode.name,
        'cycleDay': cycle.day,
        'checkIn': profile.checkIn.name,
        'history': [
          for (final m in recent)
            {'role': m.fromFriend ? 'model' : 'user', 'text': m.text},
        ],
      });
      _usedToday++;
      final data = result.data;
      return FriendReply(
        text: (data['text'] as String?)?.trim().isNotEmpty == true
            ? data['text'] as String
            : _offline(profile),
        crisis: data['crisis'] == true,
        suggestions: suggestions,
      );
    } catch (_) {
      return FriendReply(text: _offline(profile), suggestions: suggestions);
    }
  }

  bool _withinLimit() {
    final now = DateTime.now();
    if (now.year != _day.year ||
        now.month != _day.month ||
        now.day != _day.day) {
      _day = now;
      _usedToday = 0;
    }
    return _usedToday < dailyLimit;
  }

  List<String> _suggestionsFor(Profile profile, CycleStatus cycle) {
    final hardDay = cycle.mode == Mode.cozyCocoon ||
        profile.checkIn == CheckIn.crampy ||
        profile.checkIn == CheckIn.stressed;
    return hardDay
        ? const ['🪨 Smash some rocks', '🏮 Breathe with the lantern']
        : const ['✨ Today\'s 3 steps'];
  }

  String _offline(Profile profile) {
    final name = profile.displayName;
    final lines = switch (profile.vibe) {
      FriendVibe.wittyBestie => [
          "My Wi-Fi is being dramatic, $name, but I heard you. Want to tell me more anyway? I'm a great listener even offline.",
          "Signal's gone sleepy on me. Still, I'm fully on your side. Keep going, I'm here.",
        ],
      FriendVibe.cozyAuntie => [
          "Oh sweetheart, my line is a bit crackly right now. Pour yourself something warm and tell me again in a minute?",
          "I can't quite reach my notes right now, dear, but you're not alone with this. Breathe with me for a moment.",
        ],
      FriendVibe.curiousScientist => [
          "Fascinating, my connection just failed its experiment. Your feelings are valid data though. Try me again shortly?",
          "Lab's offline for a sec. While we wait: slow breaths really do calm your nervous system. Then let's chat.",
        ],
    };
    return lines[_random.nextInt(lines.length)];
  }
}
