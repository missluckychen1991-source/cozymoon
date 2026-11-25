import 'package:cozymoon/models/cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 25);

  test('no date means exploring mode', () {
    final s = CycleStatus.from(null, today: today);
    expect(s.mode, Mode.exploring);
    expect(s.day, isNull);
  });

  test('first days are menstrual and cozy cocoon', () {
    final s = CycleStatus.from(DateTime(2026, 11, 24), today: today);
    expect(s.day, 2);
    expect(s.phase, Phase.menstrual);
    expect(s.mode, Mode.cozyCocoon);
  });

  test('mid cycle is main character energy', () {
    final s = CycleStatus.from(DateTime(2026, 11, 16), today: today);
    expect(s.day, 10);
    expect(s.phase, Phase.follicular);
    expect(s.mode, Mode.mainCharacter);
    expect(CycleStatus.phaseFor(14, 28), Phase.ovulation);
    expect(CycleStatus.phaseFor(20, 28), Phase.luteal);
  });

  test('late luteal is cozy cocoon', () {
    final s = CycleStatus.from(DateTime(2026, 10, 30), today: today);
    expect(s.day, 27);
    expect(s.phase, Phase.lateLuteal);
    expect(s.mode, Mode.cozyCocoon);
  });

  test('days wrap into the next cycle', () {
    final s = CycleStatus.from(DateTime(2026, 10, 28), today: today);
    expect(s.day, 1);
  });

  test('future date is treated as unknown', () {
    expect(CycleStatus.from(DateTime(2026, 12, 1), today: today).mode,
        Mode.exploring);
  });
}
