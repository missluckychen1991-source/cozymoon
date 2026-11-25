import 'package:shared_preferences/shared_preferences.dart';

import '../content/lessons.dart';

enum StepKind { quiz, concept, action }

/// Tracks which day she's on and which of today's 3 steps are done.
/// A new day unlocks each calendar day after she first opens the hub.
class LearningStore {
  LearningStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  static const _startKey = 'cozymoon.learn.start.v1';
  static const _doneKey = 'cozymoon.learn.done.v1';

  Future<int> todayIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(_clock());
    var start = DateTime.tryParse(prefs.getString(_startKey) ?? '');
    if (start == null) {
      start = today;
      await prefs.setString(_startKey, today.toIso8601String());
    }
    final days = today.difference(_dateOnly(start)).inDays;
    return days.clamp(0, lessonDays.length - 1);
  }

  Future<Set<String>> done() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_doneKey) ?? const []).toSet();
  }

  static String key(int day, StepKind kind) => '$day:${kind.name}';

  Future<void> markDone(int day, StepKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_doneKey) ?? [];
    final k = key(day, kind);
    if (!list.contains(k)) await prefs.setStringList(_doneKey, [...list, k]);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
