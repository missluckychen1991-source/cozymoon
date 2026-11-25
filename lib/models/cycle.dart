/// Simple, offline cycle-phase math. Not medical advice: it assumes a
/// regular cycle and is only used to set the app's mood and tone.
enum Phase { menstrual, follicular, ovulation, luteal, lateLuteal }

enum Mode { cozyCocoon, mainCharacter, exploring }

extension ModeLabel on Mode {
  String get label => switch (this) {
        Mode.cozyCocoon => 'Cozy Cocoon Mode',
        Mode.mainCharacter => 'Main Character Energy',
        Mode.exploring => 'Exploring Mode',
      };

  String get emoji => switch (this) {
        Mode.cozyCocoon => '🌙',
        Mode.mainCharacter => '✨',
        Mode.exploring => '🧭',
      };

  String get blurb => switch (this) {
        Mode.cozyCocoon =>
          'Low battery is allowed. Blankets, snacks and zero guilt.',
        Mode.mainCharacter =>
          'Energy is up. A good week to start, plan or show off a little.',
        Mode.exploring =>
          'Add your last period date any time and I\'ll match your days.',
      };
}

class CycleStatus {
  const CycleStatus({this.day, this.phase, required this.mode});

  /// 1-based day of the current cycle, or null when unknown.
  final int? day;
  final Phase? phase;
  final Mode mode;

  static const unknown = CycleStatus(mode: Mode.exploring);

  static CycleStatus from(DateTime? lastStart,
      {int cycleLength = 28, DateTime? today}) {
    if (lastStart == null) return unknown;
    final length = cycleLength.clamp(21, 45);
    final now = _dateOnly(today ?? DateTime.now());
    final start = _dateOnly(lastStart);
    final diff = now.difference(start).inDays;
    if (diff < 0) return unknown;
    final day = diff % length + 1;
    final phase = phaseFor(day, length);
    final mode = (phase == Phase.menstrual || phase == Phase.lateLuteal)
        ? Mode.cozyCocoon
        : Mode.mainCharacter;
    return CycleStatus(day: day, phase: phase, mode: mode);
  }

  /// Ovulation is estimated at about 14 days before the next period.
  static Phase phaseFor(int day, int length) {
    final ovulationDay = length - 14;
    if (day <= 5) return Phase.menstrual;
    if (day < ovulationDay - 1) return Phase.follicular;
    if (day <= ovulationDay + 1) return Phase.ovulation;
    if (day > length - 5) return Phase.lateLuteal;
    return Phase.luteal;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
