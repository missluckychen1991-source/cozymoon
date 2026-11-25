import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Works once android/app/google-services.json is added (see README).
    // The web test preview runs without Firebase, using offline replies.
    if (!kIsWeb) await Firebase.initializeApp();
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
          // On a wide screen (the web preview on a computer), show a phone-sized app.
          builder: (context, child) => LayoutBuilder(
            builder: (context, c) => c.maxWidth <= 600
                ? child!
                : ColoredBox(
                    color: const Color(0xFFEDE3D6),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: ClipRect(child: child),
                      ),
                    ),
                  ),
          ),
          home: state.profile.onboarded
              ? const HomeShell()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
