import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_lao/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isDark reflects an explicit light or dark mode', () async {
    await ThemeController.instance.setMode(ThemeMode.dark);
    expect(ThemeController.instance.isDark, isTrue);

    await ThemeController.instance.setMode(ThemeMode.light);
    expect(ThemeController.instance.isDark, isFalse);
  });

  test('setMode persists the chosen mode to SharedPreferences', () async {
    await ThemeController.instance.setMode(ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), 'dark');
  });

  test('AppColors.background switches with the controller', () async {
    await ThemeController.instance.setMode(ThemeMode.light);
    final lightBackground = AppColors.background;

    await ThemeController.instance.setMode(ThemeMode.dark);
    final darkBackground = AppColors.background;

    expect(lightBackground, isNot(equals(darkBackground)));
  });
}
