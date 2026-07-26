import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/build_info.dart';
import 'config/sentry_config.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';
import 'util/page_reloader.dart';

Future<void> main() async {
  // A placeholder DSN isn't valid URI shape, and SentryFlutter.init throws
  // synchronously trying to parse an invalid one — before Flutter's own
  // error handling exists to catch it, which blanks the whole app. So
  // Sentry is only wired in once a real DSN has been set.
  if (SentryConfig.isConfigured) {
    await SentryFlutter.init(
      (options) {
        options.dsn = SentryConfig.dsn;
        // Report every unhandled error while the project is small; dial
        // this down once real traffic makes 100% sampling noisy/costly.
        options.tracesSampleRate = 1.0;
      },
      appRunner: _runApp,
    );
  } else {
    await _runApp();
  }
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const HomeLaoApp());
}

class HomeLaoApp extends StatefulWidget {
  const HomeLaoApp({super.key});

  @override
  State<HomeLaoApp> createState() => _HomeLaoAppState();
}

class _HomeLaoAppState extends State<HomeLaoApp> with WidgetsBindingObserver {
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onThemeChanged);
    _checkForUpdate();
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangePlatformBrightness() {
    // Only matters when following the OS setting; re-resolves AppColors.
    if (ThemeController.instance.value == ThemeMode.system && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Someone who's installed the PWA to their home screen can sit on a
    // stale cached build indefinitely with no other signal a new one
    // exists — check again every time they come back to the tab/app.
    if (state == AppLifecycleState.resumed) _checkForUpdate();
  }

  /// Compares this build's compiled-in commit (BuildInfo.buildSha) against
  /// a small version.json CI writes alongside the deployed bundle. A local
  /// `flutter run` has no BUILD_SHA to compare against, so it never shows
  /// the banner. The timestamp query param defeats any HTTP caching layer
  /// between the browser and GitHub Pages.
  Future<void> _checkForUpdate() async {
    if (BuildInfo.buildSha == 'dev' || _updateAvailable) return;
    try {
      final uri = Uri.base.resolve(
        'version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final sha =
          (jsonDecode(response.body) as Map<String, dynamic>)['sha']
              as String?;
      if (sha != null && sha != BuildInfo.buildSha && mounted) {
        setState(() => _updateAvailable = true);
      }
    } catch (_) {
      // Best-effort — a failed check just tries again next resume.
    }
  }

  void _reload() => reloadPage();

  @override
  Widget build(BuildContext context) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    return MaterialApp(
      // AppColors reads a plain static flag rather than InheritedWidget, so
      // a new key forces the whole tree to remount and re-read it whenever
      // the mode changes — the only clean way to propagate the flip.
      key: ValueKey(ThemeController.instance.value),
      title: 'HomeLao',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeController.instance.value,
      home: loggedIn ? const RootShell() : const LoginScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (_updateAvailable) _UpdateBanner(onReload: _reload),
          ],
        );
      },
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.system_update_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ມີລຸ້ນໃໝ່ພ້ອມໃຊ້ງານ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onReload,
                    child: Text(
                      'ອັບເດດ',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
