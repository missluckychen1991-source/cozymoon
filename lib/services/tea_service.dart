import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../models/tea.dart';
import 'kindness.dart';
import 'safety.dart';
import 'tea_seed.dart';

/// What only she sees before deciding to share.
class PrivateAnswer {
  const PrivateAnswer(
      {required this.friendNote, this.echoes = const [], this.crisis = false});
  final String friendNote;

  /// Helpful replies other women left on similar posts.
  final List<String> echoes;
  final bool crisis;
}

class PublishResult {
  const PublishResult.ok(this.post)
      : reason = null,
        crisis = false;
  const PublishResult.blocked(this.reason, {this.crisis = false}) : post = null;

  final TeaPost? post;
  final String? reason;
  final bool crisis;
  bool get ok => reason == null;
}

/// The Tea Table. With Firebase set up it uses the shared server functions so
/// everyone sees the same table. Without it, it runs on this phone only with
/// the seeded posts, which is enough to try the whole flow.
class TeaService {
  TeaService({Random? random}) : _random = random ?? Random();

  final Random _random;
  static const _localKey = 'cozymoon.tea.local.v1';
  static const _mineKey = 'cozymoon.tea.mine.v1';
  static const _huggedKey = 'cozymoon.tea.hugged.v1';

  List<TeaPost> _cache = [];

  bool get shared => Firebase.apps.isNotEmpty;

  HttpsCallable _fn(String name) =>
      FirebaseFunctions.instance.httpsCallable(name,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 25)));

  // ---------- reading ----------

  Future<List<TeaPost>> feed() async {
    List<TeaPost> posts;
    if (shared) {
      try {
        final res = await _fn('teaFeed').call<Map<String, dynamic>>({});
        posts = [
          for (final p in (res.data['posts'] as List? ?? const []))
            TeaPost.fromJson(_deepCast(p)),
        ];
        if (posts.isEmpty) posts = seedPosts();
      } catch (_) {
        posts = _cache.isNotEmpty ? _cache : seedPosts();
      }
    } else {
      posts = await _loadLocal();
    }
    final mine = await _ids(_mineKey);
    for (final p in posts) {
      p.mine = mine.contains(p.id);
    }
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = posts;
    return posts;
  }

  /// Past replies that might help with [text], best first.
  List<String> echoesFor(String text, TeaTag tag, {int max = 2}) {
    final words = _words(text);
    final scored = <(double, String)>[];
    for (final p in _cache) {
      final overlap = _words(p.text).intersection(words).length.toDouble();
      final score = overlap + (p.tag == tag ? 1.5 : 0);
      if (score < 2) continue;
      for (final r in p.replies) {
        scored.add((score + r.hugs / 100, r.text));
      }
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final s in scored.take(max)) s.$2];
  }

  // ---------- the private first answer ----------

  Future<PrivateAnswer> privateAnswer(
      String text, TeaTag tag, Profile profile) async {
    if (Safety.needsCrisisSupport(text)) {
      return const PrivateAnswer(
        crisis: true,
        friendNote:
            "Thank you for trusting me with this. What you're carrying sounds really heavy, "
            "and you deserve support from a real person right now. I've kept this private. "
            'Please reach out to one of the lines below.',
      );
    }
    final echoes = echoesFor(text, tag);
    if (shared) {
      try {
        final res = await _fn('teaFirstAnswer').call<Map<String, dynamic>>({
          'text': text,
          'tag': tag.name,
          'vibe': profile.vibe.name,
          'nickname': profile.nickname,
        });
        final note = (res.data['text'] as String?)?.trim() ?? '';
        if (res.data['crisis'] == true) {
          return PrivateAnswer(
              friendNote: note.isEmpty ? _offlineNote(tag) : note,
              crisis: true);
        }
        if (note.isNotEmpty) {
          return PrivateAnswer(friendNote: note, echoes: echoes);
        }
      } catch (_) {/* fall through to the offline note */}
    }
    return PrivateAnswer(friendNote: _offlineNote(tag), echoes: echoes);
  }

  String _offlineNote(TeaTag tag) => switch (tag) {
        TeaTag.period =>
          "Periods can be so unfair, and you're not being dramatic. Warmth on your belly, water, "
              'and rest really do help. If the pain stops you from living your day, that is worth '
              'telling a doctor about. You deserve to be taken seriously.',
        TeaTag.aging =>
          "Bodies change through the 30s, 40s and beyond, and so many women feel exactly what you're "
              "describing. It's usually a shift, not a breakdown. Keep noticing, be curious, and check "
              'with a doctor if something worries you.',
        TeaTag.solo =>
          "Building a life on your own terms takes guts, and you're doing it. The quiet wins and the "
              "lonely nights are both part of it. I'm proud of you.",
        TeaTag.venting =>
          "Okay, that is genuinely annoying and you're allowed to be fed up. Thanks for getting it out "
              "of your head. Want to smash some rocks in the Cozy Nook after this?",
      };

  // ---------- writing ----------

  Future<PublishResult> publish(String text, TeaTag tag) async {
    final trimmed = text.trim();
    if (Safety.needsCrisisSupport(trimmed)) {
      return const PublishResult.blocked(
          'Kept private so you can get real support first.',
          crisis: true);
    }
    final problem = Kindness.check(trimmed);
    if (problem != null) return PublishResult.blocked(problem);

    TeaPost post;
    if (shared) {
      try {
        final res = await _fn('teaPublish')
            .call<Map<String, dynamic>>({'text': trimmed, 'tag': tag.name});
        if (res.data['ok'] != true) {
          return PublishResult.blocked(
              res.data['reason'] as String? ?? 'This could not be shared.',
              crisis: res.data['crisis'] == true);
        }
        post = TeaPost.fromJson(_deepCast(res.data['post']));
      } catch (_) {
        return const PublishResult.blocked(
            "I couldn't reach the Tea Table. Please try again in a bit.");
      }
    } else {
      post = TeaPost(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        alias: Aliases.next(_random),
        tag: tag,
        text: trimmed,
        createdAt: DateTime.now(),
      );
      final posts = await _loadLocal()
        ..insert(0, post);
      await _saveLocal(posts);
    }
    post.mine = true;
    await _addId(_mineKey, post.id);
    _cache.insert(0, post);
    return PublishResult.ok(post);
  }

  Future<PublishResult> reply(TeaPost post, String text) async {
    final trimmed = text.trim();
    if (Safety.needsCrisisSupport(trimmed)) {
      return const PublishResult.blocked(
          "This sounds like you're going through a lot. It's kept private, please reach out for support.",
          crisis: true);
    }
    final problem = Kindness.check(trimmed);
    if (problem != null) return PublishResult.blocked(problem);

    TeaReply r;
    if (shared) {
      try {
        final res = await _fn('teaReply')
            .call<Map<String, dynamic>>({'postId': post.id, 'text': trimmed});
        if (res.data['ok'] != true) {
          return PublishResult.blocked(res.data['reason'] as String? ??
              'This reply could not be shared.');
        }
        r = TeaReply.fromJson(_deepCast(res.data['reply']));
      } catch (_) {
        return const PublishResult.blocked(
            "I couldn't reach the Tea Table. Please try again in a bit.");
      }
    } else {
      r = TeaReply(
        id: '${post.id}-r${DateTime.now().microsecondsSinceEpoch}',
        alias: Aliases.next(_random),
        text: trimmed,
        createdAt: DateTime.now(),
      );
    }
    post.replies.add(r);
    if (!shared) await _saveLocal(_cache);
    return PublishResult.ok(post);
  }

  /// One hug per post or reply from this phone.
  Future<bool> hasHugged(String id) async =>
      (await _ids(_huggedKey)).contains(id);

  Future<void> hug(TeaPost post, {TeaReply? reply}) async {
    final id = reply?.id ?? post.id;
    if (await hasHugged(id)) return;
    await _addId(_huggedKey, id);
    if (reply != null) {
      reply.hugs++;
    } else {
      post.hugs++;
    }
    if (shared) {
      try {
        await _fn('teaHug').call<Map<String, dynamic>>(
            {'postId': post.id, 'replyId': reply?.id});
      } catch (_) {/* a lost hug is fine */}
    } else {
      await _saveLocal(_cache);
    }
  }

  // ---------- local storage helpers ----------

  Future<List<TeaPost>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return seedPosts();
    try {
      return [
        for (final p in jsonDecode(raw) as List) TeaPost.fromJson(_deepCast(p))
      ];
    } catch (_) {
      return seedPosts();
    }
  }

  Future<void> _saveLocal(List<TeaPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localKey, jsonEncode([for (final p in posts) p.toJson()]));
  }

  Future<Set<String>> _ids(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? const []).toSet();
  }

  Future<void> _addId(String key, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(key) ?? [];
    if (!ids.contains(id)) await prefs.setStringList(key, [...ids, id]);
  }

  static Map<String, Object?> _deepCast(Object? v) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(v)) as Map);

  static const _stop = {
    'the',
    'and',
    'for',
    'you',
    'are',
    'but',
    'with',
    'this',
    'that',
    'have',
    'was',
    'what',
    'my',
    'me',
    'is',
    'it',
    'to',
    'of',
    'in',
    'on',
    'so',
    'just',
    'all',
    'any',
    'anyone',
    'else',
    'how',
    'do',
    'does',
    'am',
    'im',
    'its',
    'can',
    'get',
    'got',
    'feel',
    'like',
    'really',
  };

  static Set<String> _words(String s) => s
      .toLowerCase()
      .split(RegExp(r"[^a-z0-9']+"))
      .map((w) => w.replaceAll("'", ''))
      .where((w) => w.length > 2 && !_stop.contains(w))
      .map((w) =>
          w.endsWith('s') && w.length > 4 ? w.substring(0, w.length - 1) : w)
      .toSet();
}
