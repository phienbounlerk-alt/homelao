import 'package:flutter/material.dart';
import '../data/analytics_repository.dart';
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

  // Bumped whenever a Home shortcut (map card, category, trending location)
  // is tapped so SearchScreen gets a fresh Key and re-consumes the initial*
  // params below — a normal bottom-nav tap over to Search must NOT
  // re-trigger any of them, only these explicit shortcuts should.
  int _searchGeneration = 0;
  bool _searchAutoNearMe = false;
  String? _searchInitialCategory;
  String? _searchInitialQuery;

  static const _tabNames = ['home', 'search', null, 'messages', 'profile'];

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.loadForCurrentUser();
    AnalyticsRepository.track('screen_view', {'screen': _tabNames[0]});
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
    final screen = _tabNames[index];
    if (screen != null) {
      AnalyticsRepository.track('screen_view', {'screen': screen});
    }
    setState(() => _navIndex = index);
  }

  void _openNearMeSearch() {
    AnalyticsRepository.track('screen_view', {'screen': 'search'});
    setState(() {
      _searchAutoNearMe = true;
      _searchInitialCategory = null;
      _searchInitialQuery = null;
      _searchGeneration++;
      _navIndex = 1;
    });
  }

  void _openCategorySearch(String category) {
    AnalyticsRepository.track('screen_view', {'screen': 'search'});
    setState(() {
      _searchAutoNearMe = false;
      _searchInitialCategory = category;
      _searchInitialQuery = null;
      _searchGeneration++;
      _navIndex = 1;
    });
  }

  void _openLocationSearch(String city) {
    AnalyticsRepository.track('screen_view', {'screen': 'search'});
    setState(() {
      _searchAutoNearMe = false;
      _searchInitialCategory = null;
      _searchInitialQuery = city;
      _searchGeneration++;
      _navIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _bodyIndex,
        children: [
          HomeScreen(
            onNavigate: _onNavTap,
            onOpenMap: _openNearMeSearch,
            onOpenCategory: _openCategorySearch,
            onOpenLocation: _openLocationSearch,
          ),
          SearchScreen(
            key: ValueKey(_searchGeneration),
            initialNearMe: _searchAutoNearMe,
            initialCategory: _searchInitialCategory,
            initialQuery: _searchInitialQuery,
          ),
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
