import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'app_theme_mode';

/// Tracks the user's light/dark/system preference, persists it, and notifies
/// listeners so the app can rebuild when it changes.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system) {
    _load();
  }

  static final ThemeController instance = ThemeController._();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == 'light') {
      value = ThemeMode.light;
    } else if (saved == 'dark') {
      value = ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  bool get isDark {
    if (value == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return value == ThemeMode.dark;
  }
}

class AppColors {
  AppColors._();

  static bool get _dark => ThemeController.instance.isDark;

  /// Green-700 — chosen over the lighter green-600 because white text on
  /// green-600 measures ~3.3:1 contrast, below WCAG AA's 4.5:1 minimum for
  /// normal-size text. Green-700 measures ~5:1 in both directions (as text
  /// on white, and as a button fill under white text). Kept identical across
  /// light/dark so brand buttons look the same in both themes.
  static Color get primaryGreen => const Color(0xFF15803D);
  static Color get secondaryGreen =>
      _dark ? const Color(0xFF14321F) : const Color(0xFFDCFCE7);
  static Color get background =>
      _dark ? const Color(0xFF101410) : const Color(0xFFFFFFFF);
  static Color get surface =>
      _dark ? const Color(0xFF1A1F1B) : const Color(0xFFF9FAFB);
  static Color get surfaceAlt =>
      _dark ? const Color(0xFF232922) : const Color(0xFFF3F4F6);
  static Color get textPrimary =>
      _dark ? const Color(0xFFF2F4F1) : const Color(0xFF111827);
  static Color get textSecondary =>
      _dark ? const Color(0xFF98A399) : const Color(0xFF6B7280);
  static Color get success => const Color(0xFF22C55E);
  static Color get accent =>
      _dark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
  static Color get cardBorder =>
      _dark ? const Color(0xFF2B322C) : const Color(0xFFF3F4F6);
}

class AppTheme {
  AppTheme._();

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF101410)
        : const Color(0xFFFFFFFF);
    final textPrimary = isDark
        ? const Color(0xFFF2F4F1)
        : const Color(0xFF111827);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: brightness,
        primary: AppColors.primaryGreen,
        secondary: isDark ? const Color(0xFF14321F) : const Color(0xFFDCFCE7),
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.notoSansLaoTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
    );
  }

  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);
}
