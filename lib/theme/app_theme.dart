import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
//  APP THEME
//  One single place for ALL colors, fonts, and spacing.
//  Every other file imports from here — so if you want to change
//  a color across the whole app, you change it ONCE right here.
// ─────────────────────────────────────────────────────────────────

class AppTheme {
  // ── Colors ─────────────────────────────────────────────────────

  /// Main background — warm cream used everywhere
  static const Color bg = Color(0xFFFFF9F5);

  /// Light blue accent — used for badges, buttons, active states
  static const Color accent = Color(0xFFCAEAF9);

  /// Slightly darker blue — used for hero buttons, home icon circle
  static const Color accentDark = Color(0xFFC2E5FF);

  /// Soft green — used for trail tag pill backgrounds
  static const Color tagGreen = Color(0xFFD3E8D5);

  /// Dark text on green tags
  static const Color tagText = Color(0xFF131C21);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textMuted = Color(0xFF757575);
  static const Color shadow = Color(0x20000000);

  /// Thin divider lines (e.g. between stats)
  static const Color divider = Color(0x1A375463);

  // ── Font ───────────────────────────────────────────────────────

  /// The Hebrew font used throughout the app.
  /// Make sure it's declared in pubspec.yaml under flutter > fonts.
  static const String font = 'SimplerPro_HLAR';

  // ── Reusable TextStyles ────────────────────────────────────────

  static const TextStyle headingLarge = TextStyle(
    fontFamily: font,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: black,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: black,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: black,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: black,
  );

  static const TextStyle labelMuted = TextStyle(
    fontFamily: font,
    fontSize: 12,
    color: textMuted,
  );

  static const TextStyle tagStyle = TextStyle(
    fontFamily: font,
    fontSize: 9,
    color: tagText,
  );

  // ── Border Radius ──────────────────────────────────────────────

  static const double radiusCard = 20;
  static const double radiusPill = 28;
  static const double radiusBadge = 15;
  static const double radiusSmall = 12;

  // ── Shadows ────────────────────────────────────────────────────

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: shadow, blurRadius: 4, offset: Offset(1, 1)),
  ];

  static const List<BoxShadow> navShadow = [
    BoxShadow(color: shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> ctaShadow = [
    BoxShadow(
      color: Color(0x339DB1BF),
      blurRadius: 4.2,
      offset: Offset(0, 1),
    ),
  ];

  // ── MaterialApp ThemeData ──────────────────────────────────────
  //  Used once in main.dart → MaterialApp(theme: AppTheme.theme)

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A8A6A),
        ),
        useMaterial3: true,
        fontFamily: font,
        scaffoldBackgroundColor: bg,
      );
}
