import 'dart:math';
import 'dart:typed_data';

import 'package:cozymoon/app_state.dart';
import 'package:cozymoon/content/stories.dart';
import 'package:cozymoon/nook/lantern.dart';
import 'package:cozymoon/nook/rocks_game.dart';
import 'package:cozymoon/nook/sound_mixer.dart';
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
              find.byKey(const Key('comfort-prompt')).evaluate().isNotEmpty;
      expect(opened, isTrue, reason: 'seed $seed');
    }
  });
}
