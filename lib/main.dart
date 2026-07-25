import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
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
