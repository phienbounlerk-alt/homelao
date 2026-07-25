import 'package:flutter/material.dart';
import '../data/favorites_store.dart';
import '../theme/app_theme.dart';
import '../widgets/home_bottom_nav.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'post_listing_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Persistent bottom-nav shell. Home/Search/Messages/Profile are kept alive
/// as [IndexedStack] tabs so the bottom nav never disappears when switching
/// between them; Post Listing stays a pushed modal route since it's an
/// action, not a tab.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.loadForCurrentUser();
  }

  // HomeBottomNav index 2 ("add") has no tab body, so it's excluded here.
  int get _bodyIndex => _navIndex < 2 ? _navIndex : _navIndex - 1;

  void _onNavTap(int index) {
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PostListingScreen()));
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _bodyIndex,
        children: [
          HomeScreen(onNavigate: _onNavTap),
          const SearchScreen(),
          const MessagesScreen(),
          ProfileScreen(onNavigate: _onNavTap),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
