import 'dart:math';

enum TeaTag { period, aging, solo, venting }

extension TeaTagLabel on TeaTag {
  String get label => switch (this) {
        TeaTag.period => 'Period & Pain',
        TeaTag.aging => 'Enjoying Aging',
        TeaTag.solo => 'Solo Life',
        TeaTag.venting => 'Just Venting',
      };

  String get emoji => switch (this) {
        TeaTag.period => '🩸',
        TeaTag.aging => '🌿',
        TeaTag.solo => '🕯️',
        TeaTag.venting => '🌀',
      };
}

TeaTag tagFromName(Object? name) =>
    TeaTag.values.where((t) => t.name == name).firstOrNull ?? TeaTag.venting;

class TeaReply {
  TeaReply(
      {required this.id,
      required this.alias,
      required this.text,
      required this.createdAt,
      this.hugs = 0});

  final String id;
  final String alias;
  final String text;
  final DateTime createdAt;
  int hugs;

  Map<String, Object?> toJson() => {
        'id': id,
        'alias': alias,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'hugs': hugs
      };

  factory TeaReply.fromJson(Map<String, Object?> j) => TeaReply(
        id: j['id'] as String,
        alias: j['alias'] as String,
        text: j['text'] as String,
        createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
        hugs: (j['hugs'] as num?)?.toInt() ?? 0,
      );
}

class TeaPost {
  TeaPost({
    required this.id,
    required this.alias,
    required this.tag,
    required this.text,
    required this.createdAt,
    this.hugs = 0,
    List<TeaReply>? replies,
    this.mine = false,
  }) : replies = replies ?? [];

  final String id;
  final String alias;
  final TeaTag tag;
  final String text;
  final DateTime createdAt;
  int hugs;
  final List<TeaReply> replies;

  /// Only known on this phone, never sent anywhere.
  bool mine;

  Map<String, Object?> toJson() => {
        'id': id,
        'alias': alias,
        'tag': tag.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'hugs': hugs,
        'replies': [for (final r in replies) r.toJson()],
      };

  factory TeaPost.fromJson(Map<String, Object?> j) => TeaPost(
        id: j['id'] as String,
        alias: j['alias'] as String,
        tag: tagFromName(j['tag']),
        text: j['text'] as String,
        createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
        hugs: (j['hugs'] as num?)?.toInt() ?? 0,
        replies: [
          for (final r in (j['replies'] as List? ?? const []))
            TeaReply.fromJson(Map<String, Object?>.from(r as Map)),
        ],
      );
}

/// A fresh, cute one-time name for every post and reply, so nobody can be
/// followed across threads.
class Aliases {
  static const _first = [
    'Cozy',
    'Quiet',
    'Sleepy',
    'Warm',
    'Minty',
    'Gentle',
    'Soft',
    'Sunny',
    'Velvet',
    'Misty',
    'Honey',
    'Little',
    'Brave',
    'Calm',
    'Rosy',
    'Lazy',
  ];
  static const _second = [
    'Matcha',
    'Fern',
    'Plum',
    'Ginger',
    'Owl',
    'Biscuit',
    'Moth',
    'Cloud',
    'Peach',
    'Sparrow',
    'Mochi',
    'Lantern',
    'Willow',
    'Otter',
    'Chai',
    'Clover',
  ];

  static String next([Random? random]) {
    final r = random ?? Random();
    return '${_first[r.nextInt(_first.length)]} ${_second[r.nextInt(_second.length)]} #${r.nextInt(90) + 10}';
  }
}

String timeAgo(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
