import 'package:cozymoon/content/lessons.dart';
import 'package:cozymoon/screens/learn_screen.dart';
import 'package:cozymoon/services/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('9 lessons: 3 days, each with a valid quiz, idea and action', () {
    expect(lessonDays, hasLength(3));
    for (final d in lessonDays) {
      expect(d.quiz.options.length, greaterThanOrEqualTo(2));
      expect(d.quiz.answer, inInclusiveRange(0, d.quiz.options.length - 1));
      expect(d.concept.points, isNotEmpty);
      expect(d.action.snack, isNotEmpty);
      expect(d.action.stretch, isNotEmpty);
    }
  });

  test('a new day unlocks each calendar day and stops at the last day',
      () async {
    var now = DateTime(2026, 11, 25, 22);
    final store = LearningStore(clock: () => now);
    expect(await store.todayIndex(), 0);
    now = DateTime(2026, 11, 26, 7);
    expect(await store.todayIndex(), 1);
    now = DateTime(2026, 12, 20);
    expect(await store.todayIndex(), lessonDays.length - 1);
  });

  testWidgets('finish all 3 steps today', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await _settle(tester);
    expect(find.text('0 of 3 done · about 5 minutes in total'), findsOneWidget);

    // Quiz: pick the right answer, see the explanation, finish.
    await tester.tap(find.byKey(const Key('step-quiz')));
    await _settle(tester);
    await tester.tap(find.byKey(Key('option-${lessonDays[0].quiz.answer}')));
    await _settle(tester, 2);
    expect(find.byKey(const Key('quiz-explain')), findsOneWidget);
    await tester.tap(find.byKey(const Key('step-done')));
    await _settle(tester);
    expect(find.text('1 of 3 done · about 5 minutes in total'), findsOneWidget);

    for (final k in ['concept', 'action']) {
      await tester.tap(find.byKey(Key('step-$k')));
      await _settle(tester);
      await tester.scrollUntilVisible(find.byKey(const Key('step-done')), 200,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const Key('step-done')));
      await _settle(tester);
    }
    expect(find.textContaining('All done for today'), findsOneWidget);
    expect((await LearningStore().done()).length, 3);
  });

  testWidgets('preview tomorrow is readable but does not count',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('preview-tomorrow')));
    await _settle(tester);
    await tester.tap(find.text(lessonDays[1].concept.title));
    await _settle(tester);
    expect(find.textContaining('Sneak peek'), findsOneWidget);
    expect(find.byKey(const Key('step-done')), findsNothing);
    await tester.pageBack();
    await _settle(tester);
    expect((await LearningStore().done()), isEmpty);
  });
}
