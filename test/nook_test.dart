import 'dart:math';
import 'dart:typed_data';

import 'package:cozymoon/app_state.dart';
import 'package:cozymoon/content/stories.dart';
import 'package:cozymoon/nook/bubble_wrap.dart';
import 'package:cozymoon/nook/lantern.dart';
import 'package:cozymoon/nook/rocks_game.dart';
import 'package:cozymoon/nook/sand_garden.dart';
import 'package:cozymoon/nook/sound_mixer.dart';
import 'package:cozymoon/nook/tea_pour.dart';
import 'package:cozymoon/screens/cozy_nook_screen.dart';
import 'package:cozymoon/services/ambient_service.dart';
import 'package:cozymoon/services/sound_synth.dart';
import 'package:cozymoon/services/story_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sound synth', () {
    void checkWav(Uint8List w, {double? seconds}) {
      final b = ByteData.sublistView(w);
      expect(String.fromCharCodes(w.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(w.sublist(8, 12)), 'WAVE');
      expect(b.getUint32(24, Endian.little), SoundSynth.sampleRate);
      final dataLen = b.getUint32(40, Endian.little);
      expect(w.length, 44 + dataLen);
      if (seconds != null) {
        expect(dataLen ~/ 2, (seconds * SoundSynth.sampleRate).round());
      }
      var peak = 0;
      for (var i = 44; i < w.length; i += 2) {
        peak = max(peak, b.getInt16(i, Endian.little).abs());
      }
      expect(peak, greaterThan(500), reason: 'should not be silent');
      expect(peak, lessThanOrEqualTo(32767 * 0.91), reason: 'should not clip');
    }

    test('rain, pad, fire and pop are valid, audible and not clipping', () {
      checkWav(SoundSynth.rain(seconds: 2), seconds: 2);
      checkWav(SoundSynth.warmPad(seconds: 2), seconds: 2);
      checkWav(SoundSynth.fireplace(seconds: 2), seconds: 2);
      checkWav(SoundSynth.pop());
      checkWav(SoundSynth.bubble());
      checkWav(SoundSynth.chime());
      checkWav(SoundSynth.pour(seconds: 2), seconds: 2);
    });
  });

  test('story maker falls back to a matching library story offline', () async {
    final s = await StoryService(random: Random(1))
        .write('Night Train', 'Sleepy & Slow');
    expect(s.tag, StoryTag.sleepy);
    expect(stories, hasLength(6));
  });

  testWidgets('smashing rocks counts up', (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(
        home: RocksGame(sfx: Sfx(enabled: false), random: Random(2))));
    await _settle(tester, 30);
    final area = tester.getRect(find.byKey(const Key('rocks-area')));
    var hit = false;
    for (var y = area.bottom - 20; y > area.top && !hit; y -= 30) {
      for (var x = area.left + 20; x < area.right && !hit; x += 30) {
        await tester.tapAt(Offset(x, y));
        await tester.pump(const Duration(milliseconds: 16));
        hit = find.textContaining('smashed').evaluate().isNotEmpty;
      }
    }
    expect(hit, isTrue);
  });

  testWidgets('lantern guides breathing while held', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: BreathingLantern()));
    expect(find.text('Press and hold the lantern'), findsOneWidget);
    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(const Key('lantern'))));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Breathe in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Breathe out'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('calm breaths'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Press and hold the lantern'), findsOneWidget);
  });

  testWidgets('bubble wrap pops, then a fresh sheet rolls in', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
        MaterialApp(home: BubbleWrapGame(sfx: Sfx(enabled: false))));
    await tester.pump();
    final bubbles = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('bubble-') &&
        (w.key! as ValueKey<String>).value != 'bubble-sheet');
    final count = bubbles.evaluate().length;
    expect(count, greaterThanOrEqualTo(BubbleWrapGame.cols * 3));

    await tester.tapAt(tester.getCenter(find.byKey(const Key('bubble-0'))));
    await tester.pump();
    expect(find.textContaining('1 popped'), findsOneWidget);
    // Tapping a popped bubble again does nothing.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('bubble-0'))));
    await tester.pump();
    expect(find.textContaining('1 popped'), findsOneWidget);

    // Swipe along the first row to pop several at once.
    final start = tester.getCenter(find.byKey(const Key('bubble-1')));
    final end = tester
        .getCenter(find.byKey(const Key('bubble-${BubbleWrapGame.cols - 1}')));
    await tester.dragFrom(start, end - start);
    await tester.pump();
    expect(
        find.textContaining('${BubbleWrapGame.cols} popped'), findsOneWidget);

    for (var i = BubbleWrapGame.cols; i < count; i++) {
      await tester.tapAt(tester.getCenter(find.byKey(Key('bubble-$i'))));
    }
    await tester.pump();
    expect(find.textContaining('fresh sheet'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('$count popped'), findsOneWidget);
    // The new sheet is poppable again.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('bubble-0'))));
    await tester.pump();
    expect(find.textContaining('${count + 1} popped'), findsOneWidget);
  });

  testWidgets('sand garden rakes lines and smooths them away', (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(home: SandGarden(random: Random(1))));
    await tester.pump();
    expect(find.textContaining('Drag slowly'), findsOneWidget);
    final c = tester.getCenter(find.byKey(const Key('sand-area')));
    final g = await tester.startGesture(c);
    for (var i = 0; i < 20; i++) {
      await g.moveBy(const Offset(8, 3));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump();
    expect(find.textContaining('Breathe out'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sand-smooth')));
    await _settle(tester, 12);
    expect(find.textContaining('Drag slowly'), findsOneWidget);
  });

  testWidgets('tea pours while held, never spills, and glows when full',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(
        MaterialApp(home: TeaPour(sfx: Sfx(enabled: false), fillSeconds: 2)));
    await tester.pump();
    expect(find.text('Press and hold anywhere to pour.'), findsOneWidget);
    final area = tester.getCenter(find.byKey(const Key('tea-area')));

    var g = await tester.startGesture(area);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Pouring'), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('never spill'), findsOneWidget);
    expect(find.byKey(const Key('tea-another')), findsNothing);

    g = await tester.startGesture(area);
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('is ready'), findsOneWidget);
    await g.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('is ready'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tea-another')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Press and hold anywhere to pour.'), findsOneWidget);
  });

  testWidgets('all five games open from the cozy nook', (tester) async {
    _phone(tester);
    final state = AppState(ambient: AmbientService(enabled: false));
    await state.load();
    await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(home: CozyNookScreen(random: Random(1)))));
    await _settle(tester, 2);
    final games = {
      'game-rocks': RocksGame,
      'game-lantern': BreathingLantern,
      'game-bubbles': BubbleWrapGame,
      'game-sand': SandGarden,
      'game-tea': TeaPour,
    };
    for (final e in games.entries) {
      await tester.scrollUntilVisible(find.byKey(Key(e.key)), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(Key(e.key)));
      await _settle(tester, 5);
      expect(find.byType(e.value), findsOneWidget, reason: e.key);
      await tester.pageBack();
      await _settle(tester, 5);
    }
  });

  testWidgets('cozy nook: open a story and turn on rain with the mini player',
      (tester) async {
    _phone(tester);
    final state = AppState(ambient: AmbientService(enabled: false));
    await state.load();
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
        home: Scaffold(
          body: CozyNookScreen(random: Random(3)),
          bottomNavigationBar: MiniPlayer(ambient: state.ambient),
        ),
      ),
    ));
    await _settle(tester, 2);

    await tester.scrollUntilVisible(find.text('The Night Train North'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('The Night Train North'));
    await _settle(tester, 5);
    expect(find.byKey(const Key('story-title')), findsOneWidget);
    await tester.pageBack();
    await _settle(tester, 5);

    expect(find.byKey(const Key('mini-player')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('mix-rain')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await _settle(tester, 2);
    await tester.drag(find.byKey(const Key('mix-rain')), const Offset(150, 0));
    await _settle(tester, 2);
    expect(state.ambient.volumes[Ambient.rain], greaterThan(0));
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
  });

  testWidgets('mystery envelope always opens something', (tester) async {
    _phone(tester);
    final state = AppState(ambient: AmbientService(enabled: false));
    await state.load();
    for (var seed = 0; seed < 6; seed++) {
      await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(
            key: ValueKey(seed), home: CozyNookScreen(random: Random(seed))),
      ));
      await _settle(tester, 2);
      await tester.tap(find.byKey(const Key('envelope')));
      await _settle(tester, 5);
      final opened =
          find.byKey(const Key('story-title')).evaluate().isNotEmpty ||
              find.byType(RocksGame).evaluate().isNotEmpty ||
              find.byType(BreathingLantern).evaluate().isNotEmpty ||
              find.byType(BubbleWrapGame).evaluate().isNotEmpty ||
              find.byType(SandGarden).evaluate().isNotEmpty ||
              find.byType(TeaPour).evaluate().isNotEmpty ||
              find.byKey(const Key('comfort-prompt')).evaluate().isNotEmpty;
      expect(opened, isTrue, reason: 'seed $seed');
    }
  });
}
