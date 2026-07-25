import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/sentry_config.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onThemeChanged);
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
    );
  }
}
