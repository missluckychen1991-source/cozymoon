import 'package:cozymoon/models/profile.dart';
import 'package:cozymoon/models/tea.dart';
import 'package:cozymoon/screens/tea_table_screen.dart';
import 'package:cozymoon/app_state.dart';
import 'package:cozymoon/services/kindness.dart';
import 'package:cozymoon/services/tea_seed.dart';
import 'package:cozymoon/services/tea_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('8 seeded posts with 2 or 3 replies each', () {
    final posts = seedPosts();
    expect(posts, hasLength(8));
    for (final p in posts) {
      expect(p.replies.length, inInclusiveRange(2, 3));
    }
    expect(posts.map((p) => p.tag).toSet(), TeaTag.values.toSet());
  });

  test('kindness check', () {
    expect(Kindness.check('any tips for day 2 cramps?'), isNull);
    expect(Kindness.check('message me at me@mail.com'), contains('email'));
    expect(Kindness.check('my number is +84 912 345 678'), contains('phone'));
    expect(Kindness.check('find me @cozygirl99'), contains('handle'));
    expect(Kindness.check("you're so pathetic"), contains('hurtful'));
    expect(Kindness.check('just stop taking your meds'), contains('hurtful'));
  });

  test('private answer has a friend note and echoes from similar posts',
      () async {
    final s = TeaService();
    await s.feed();
    final a = await s.privateAnswer(
        'My period cramps are so bad at work', TeaTag.period, const Profile());
    expect(a.crisis, isFalse);
    expect(a.friendNote, isNotEmpty);
    expect(a.echoes, isNotEmpty);
  });

  test('crisis posts are kept private and never published', () async {
    final s = TeaService();
    await s.feed();
    final a = await s.privateAnswer(
        'I want to kill myself', TeaTag.venting, const Profile());
    expect(a.crisis, isTrue);
    final r = await s.publish('I want to kill myself', TeaTag.venting);
    expect(r.ok, isFalse);
    expect(r.crisis, isTrue);
    expect(
        (await s.feed()).any((p) => p.text.contains('kill myself')), isFalse);
  });

  test('publish, reply and hug once', () async {
    final s = TeaService();
    await s.feed();
    final r = await s.publish(
        'First time trying solo travel next month!', TeaTag.solo);
    expect(r.ok, isTrue);
    final post = r.post!;
    expect(post.mine, isTrue);
    expect(RegExp(r'^\w+ \w+ #\d\d$').hasMatch(post.alias), isTrue);

    expect((await s.reply(post, 'You are an idiot')).ok, isFalse);
    expect(
        (await s.reply(post, 'So exciting, enjoy every minute!')).ok, isTrue);

    await s.hug(post);
    await s.hug(post);
    expect(post.hugs, 1);

    final again = await TeaService().feed();
    final saved = again.firstWhere((p) => p.id == post.id);
    expect(saved.mine, isTrue);
    expect(saved.replies, hasLength(1));
    expect(saved.hugs, 1);
  });

  testWidgets('ask, see the private answer, keep it private', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final state = AppState();
    await state.load();
    await tester.pumpWidget(AppScope(
      state: state,
      child: const MaterialApp(home: TeaTableScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TeaPostCard), findsWidgets);

    await tester.tap(find.byKey(const Key('tea-ask')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(
        find.byKey(const Key('tea-text')), 'Day 2 cramps at work again, help');
    await tester.tap(find.text('🩸 Period & Pain'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('tea-continue')));
    await tester.tap(find.byKey(const Key('tea-continue')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('tea-friend-note')), findsOneWidget);
    expect(find.textContaining('Only you can see this'), findsOneWidget);

    await tester.scrollUntilVisible(
        find.byKey(const Key('tea-keep-private')), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const Key('tea-keep-private')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('cramps at work again'), findsNothing);
  });
}
