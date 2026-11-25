/// Who the friend is talking to. Everything here stays on the phone.
enum FriendVibe { wittyBestie, cozyAuntie, curiousScientist }

extension FriendVibeLabel on FriendVibe {
  String get label => switch (this) {
        FriendVibe.wittyBestie => 'Witty Bestie',
        FriendVibe.cozyAuntie => 'Cozy Auntie',
        FriendVibe.curiousScientist => 'Curious Scientist',
      };

  String get emoji => switch (this) {
        FriendVibe.wittyBestie => '😏',
        FriendVibe.cozyAuntie => '🫖',
        FriendVibe.curiousScientist => '🔬',
      };
}

enum CheckIn { crampy, stressed, prettyGood, exploring }

extension CheckInLabel on CheckIn {
  String get label => switch (this) {
        CheckIn.crampy => 'Bleeding / Crampy',
        CheckIn.stressed => 'Stressed / Brain-Foggy',
        CheckIn.prettyGood => 'Feeling Pretty Good',
        CheckIn.exploring => 'Just Exploring',
      };

  String get emoji => switch (this) {
        CheckIn.crampy => '🩸',
        CheckIn.stressed => '🌀',
        CheckIn.prettyGood => '🌤️',
        CheckIn.exploring => '🧭',
      };
}

class Profile {
  const Profile({
    this.nickname,
    this.vibe = FriendVibe.wittyBestie,
    this.checkIn = CheckIn.exploring,
    this.lastPeriodStart,
    this.cycleLength = 28,
    this.onboarded = false,
  });

  /// Null means "keep me nameless".
  final String? nickname;
  final FriendVibe vibe;
  final CheckIn checkIn;
  final DateTime? lastPeriodStart;
  final int cycleLength;
  final bool onboarded;

  String get displayName => (nickname == null || nickname!.trim().isEmpty)
      ? 'friend'
      : nickname!.trim();

  Profile copyWith({
    String? nickname,
    bool clearNickname = false,
    FriendVibe? vibe,
    CheckIn? checkIn,
    DateTime? lastPeriodStart,
    bool clearLastPeriodStart = false,
    int? cycleLength,
    bool? onboarded,
  }) {
    return Profile(
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      vibe: vibe ?? this.vibe,
      checkIn: checkIn ?? this.checkIn,
      lastPeriodStart: clearLastPeriodStart
          ? null
          : (lastPeriodStart ?? this.lastPeriodStart),
      cycleLength: cycleLength ?? this.cycleLength,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, Object?> toJson() => {
        'nickname': nickname,
        'vibe': vibe.name,
        'checkIn': checkIn.name,
        'lastPeriodStart': lastPeriodStart?.toIso8601String(),
        'cycleLength': cycleLength,
        'onboarded': onboarded,
      };

  factory Profile.fromJson(Map<String, Object?> json) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    final start = json['lastPeriodStart'];
    return Profile(
      nickname: json['nickname'] as String?,
      vibe: byName(FriendVibe.values, json['vibe'], FriendVibe.wittyBestie),
      checkIn: byName(CheckIn.values, json['checkIn'], CheckIn.exploring),
      lastPeriodStart: start is String ? DateTime.tryParse(start) : null,
      cycleLength: (json['cycleLength'] as num?)?.toInt() ?? 28,
      onboarded: json['onboarded'] == true,
    );
  }
}
