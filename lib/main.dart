import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Works once android/app/google-services.json is added (see README).
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase yet: the friend uses warm offline replies.
  }
  final state = AppState();
  await state.load();
  runApp(CozyMoonApp(state: state));
}

class CozyMoonApp extends StatelessWidget {
  const CozyMoonApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'CozyMoon',
          debugShowCheckedModeBanner: false,
          theme: cozyDayTheme,
          darkTheme: cozyNightTheme,
          themeMode: state.nightMode ? ThemeMode.dark : ThemeMode.light,
          home: state.profile.onboarded
              ? const HomeShell()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
