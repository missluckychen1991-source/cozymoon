import 'package:flutter/material.dart';

/// "Warm Tea" day theme and "Cozy Dark" night theme.
class CozyColors {
  static const terracotta = Color(0xFFD97757);
  static const sage = Color(0xFF7A9E7E);
  static const amber = Color(0xFFF2B866);

  static const dayBackground = Color(0xFFFAF5EE);
  static const dayCard = Color(0xFFFFFFFF);
  static const dayText = Color(0xFF2D242C);

  static const nightBackground = Color(0xFF1F1A24);
  static const nightCard = Color(0xFF2B2433);
  static const nightText = Color(0xFFF5EDE4);
}

ThemeData _build(Brightness brightness) {
  final day = brightness == Brightness.light;
  final background =
      day ? CozyColors.dayBackground : CozyColors.nightBackground;
  final card = day ? CozyColors.dayCard : CozyColors.nightCard;
  final text = day ? CozyColors.dayText : CozyColors.nightText;

  final scheme = ColorScheme.fromSeed(
    seedColor: CozyColors.terracotta,
    brightness: brightness,
  ).copyWith(
    primary: CozyColors.terracotta,
    secondary: CozyColors.sage,
    tertiary: CozyColors.amber,
    surface: card,
    onSurface: text,
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    cardTheme: CardTheme(
      color: card,
      elevation: day ? 2 : 0,
      shadowColor: Colors.black12,
      shape: shape,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        foregroundColor: text,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: card,
      side: BorderSide(color: CozyColors.terracotta.withValues(alpha: 0.35)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: CozyColors.terracotta.withValues(alpha: 0.18),
    ),
  );
}

final cozyDayTheme = _build(Brightness.light);
final cozyNightTheme = _build(Brightness.dark);
