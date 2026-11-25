import 'package:cozymoon/services/safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flags crisis language', () {
    for (final t in [
      'I want to kill myself',
      'thinking about suicide lately',
      "I don't want to wake up tomorrow",
      'I keep cutting myself',
      'my boyfriend hits me',
      "I'm not safe at home",
    ]) {
      expect(Safety.needsCrisisSupport(t), isTrue, reason: t);
    }
  });

  test('does not flag everyday venting', () {
    for (final t in [
      'These cramps are killing me',
      'I could die of embarrassment lol',
      'Annoyed at everyone today',
      'Worried about getting older',
    ]) {
      expect(Safety.needsCrisisSupport(t), isFalse, reason: t);
    }
  });
}
