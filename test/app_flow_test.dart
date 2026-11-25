import 'package:cozymoon/app_state.dart';
import 'package:cozymoon/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CozyMoonApp> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final state = AppState();
  await state.load();
  return CozyMoonApp(state: state);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('skipping onboarding lands on Home with defaults',
      (tester) async {
    await tester.pumpWidget(await _app(tester));
    await tester.tap(find.byKey(const Key('skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Exploring Mode'), findsOneWidget);
    expect(find.text('Confide or Ask Me Anything'), findsOneWidget);
  });

  testWidgets('chat replies offline and shows crisis help', (tester) async {
    await tester.pumpWidget(await _app(tester));
    await tester.tap(find.byKey(const Key('skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('open-chat')));
    await tester.tap(find.byKey(const Key('open-chat')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
        find.byKey(const Key('chat-input')), 'Period cramps suck');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Period cramps suck'), findsOneWidget);
    expect(find.textContaining('You matter'), findsNothing);

    await tester.enterText(
        find.byKey(const Key('chat-input')), 'I want to end my life');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('You matter'), findsOneWidget);
  });

  testWidgets('burn after venting wipes the page when turned off',
      (tester) async {
    await tester.pumpWidget(await _app(tester));
    await tester.tap(find.byKey(const Key('skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('open-chat')));
    await tester.tap(find.byKey(const Key('open-chat')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('burn')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byKey(const Key('chat-input')), 'secret rant');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('secret rant'), findsOneWidget);

    await tester.tap(find.byKey(const Key('burn')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('secret rant'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cozymoon.chat.v1') ?? '',
        isNot(contains('secret rant')));
  });
}
