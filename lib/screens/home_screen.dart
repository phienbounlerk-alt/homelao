import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/notification_repository.dart';
import '../data/property_repository.dart';
import '../models/app_notification.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/category_item.dart';
import '../widgets/feature_chip.dart';
import '../widgets/error_state.dart';
import '../widgets/location_chip.dart';
import '../widgets/property_card.dart';
import 'help_center_screen.dart';
import 'moving_service_screen.dart';
import 'notifications_screen.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the parent shell's active tab (or pushes a route for the
  /// "add listing" action), using the same index scheme as [HomeBottomNav].
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    (Icons.apartment_rounded, 'ອາພາດເມັນ'),
    (Icons.bed_rounded, 'ຫ້ອງເຊົ່າ'),
    (Icons.house_rounded, 'ເຮືອນ'),
    (Icons.location_city_rounded, 'ຄອນໂດ'),
    (Icons.holiday_village_rounded, 'ວິນລາ'),
    (Icons.chair_rounded, 'ຫ້ອງການ'),
    (Icons.map_rounded, 'ທີ່ດິນ'),
    (Icons.grid_view_rounded, 'ອື່ນໆ'),
  ];

  // Each shortcut jumps to a screen that actually delivers on its label —
  // no tiles for features the app doesn't have (a loan calculator and a
  // move-in service were dropped for exactly that reason).
  List<(IconData, String, VoidCallback)> _features(BuildContext context) => [
    (Icons.verified_rounded, 'ລາຍການ\nຢືນຢັນແລ້ວ', () => widget.onNavigate(1)),
    (Icons.near_me_rounded, 'ເຊົ່າ\nໃກ້ຄຽງ', () => widget.onNavigate(1)),
    (Icons.sell_rounded, 'ລາຄາ\nຖືກສຸດ', () => widget.onNavigate(1)),
    (Icons.chat_bubble_rounded, 'ແຊັດ\nທັນທີ', () => widget.onNavigate(3)),
    (
      Icons.local_shipping_rounded,
      'ບໍລິການ\nຂົນສົ່ງເຄື່ອງ',
      () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MovingServiceScreen())),
    ),
    (
      Icons.support_agent_rounded,
      'ຊ່ວຍເຫຼືອ\n24 ຊມ.',
      () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
    ),
  ];

  List<Property> _recommended = [];
  List<Property> _featured = [];
  List<Property> _newestListings = [];
  bool _loading = true;
  bool _error = false;

  StreamSubscription<List<Property>>? _newestSub;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _newestSub = PropertyRepository.streamNewest().listen((rows) {
      if (!mounted) return;
      setState(() => _newestListings = rows);
    }, onError: (e, st) => Sentry.captureException(e, stackTrace: st));
  }

  @override
  void dispose() {
    _newestSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait([
        PropertyRepository.fetchRecommended(),
        PropertyRepository.fetchFeatured(),
      ]);
      if (!mounted) return;
      setState(() {
        _recommended = results[0];
        _featured = results[1];
        _loading = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  static const _trendingLocations = [
    (
      'ວຽງຈັນ',
      'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=100&q=80',
    ),
    (
      'ຫລວງພະບາງ',
      'https://images.unsplash.com/photo-1528181304800-259b08848526?w=100&q=80',
    ),
    (
      'ປາກເຊ',
      'https://images.unsplash.com/photo-1512100356356-de1b84283e18?w=100&q=80',
    ),
    (
      'ສະຫວັນນະເຂດ',
      'https://images.unsplash.com/photo-1500835556837-99ac94a94552?w=100&q=80',
    ),
    (
      'ທ່າແຂກ',
      'https://images.unsplash.com/photo-1509644851169-2acc08aa25b5?w=100&q=80',
    ),
    (
      'ວັງວຽງ',
      'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=100&q=80',
    ),
  ];

  List<Property> get _recentlyViewed =>
      [..._recommended, ..._newestListings].take(5).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          );
        },
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(),
                      const SizedBox(height: 18),
                      _Brand(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  onSearchTap: () => widget.onNavigate(1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _DiscoverBanner(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final c in _categories.sublist(0, 4))
                            CategoryItem(icon: c.$1, label: c.$2),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final c in _categories.sublist(4, 8))
                            CategoryItem(icon: c.$1, label: c.$2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Builder(
                      builder: (context) {
                        final features = _features(context);
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                for (final f in features.sublist(0, 3))
                                  Expanded(
                                    child: FeatureChip(
                                      icon: f.$1,
                                      label: f.$2,
                                      onTap: f.$3,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                for (final f in features.sublist(3, 6))
                                  Expanded(
                                    child: FeatureChip(
                                      icon: f.$1,
                                      label: f.$2,
                                      onTap: f.$3,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (!_error && _featured.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _SectionHeader(title: '★ ຊັບສິນເດັ່ນ'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _featured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) =>
                          PropertyCard(property: _featured[i]),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
                  child: _SectionHeader(
                    title: 'ແນະນຳສຳລັບທ່ານ',
                    subtitle: 'ຊັບສິນທີ່ຄັດເລືອກຕາມຄວາມມັກຂອງທ່ານ.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: _error
                      ? ErrorState(onRetry: _loadProperties)
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommended.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, i) =>
                              PropertyCard(property: _recommended[i]),
                        ),
                ),
              ),
              if (!_error) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: _SectionHeader(title: 'ລາຍການໃໝ່ລ່າສຸດ'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _newestListings.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) =>
                          PropertyCard(property: _newestListings[i]),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: _SectionHeader(title: 'ທຳເລຍອດນິຍົມ'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingLocations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => LocationChip(
                      name: _trendingLocations[i].$1,
                      imageUrl: _trendingLocations[i].$2,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: _MapCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: _SectionHeader(title: 'ເບິ່ງລ່າສຸດ'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentlyViewed.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      return _RecentThumb(property: _recentlyViewed[i]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  // Created once and held for this State's lifetime so rebuilds (e.g. from
  // unrelated setState calls elsewhere on Home) don't tear down and
  // resubscribe the realtime notifications stream every time.
  late final _notifications = NotificationRepository.streamMine();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.location_on, color: AppColors.primaryGreen, size: 22),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ທີ່ຢູ່ປັດຈຸບັນ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ນະຄອນຫຼວງວຽງຈັນ, ລາວ',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        StreamBuilder<List<AppNotification>>(
          stream: _notifications,
          builder: (context, snapshot) {
            final unread = snapshot.data?.where((n) => !n.read).length ?? 0;
            return Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Tooltip(
                    message: 'ແຈ້ງເຕືອນ',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 26,
                          color: AppColors.textPrimary,
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        const CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80',
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Home',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Lao',
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ຄົ້ນຫາທີ່ຢູ່ອາໄສທີ່ດີທີ່ສຸດສຳລັບທ່ານ',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchBarDelegate({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: _SearchBar(onTap: onSearchTap),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) =>
      onSearchTap != oldDelegate.onSearchTap;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ຄົ້ນຫາອາພາດເມັນ, ເຮືອນ, ຄອນໂດ...',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Tooltip(
                          message: 'ຕົວກອງ',
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.primaryGreen,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
          child: InkWell(
            onTap: () {},
            customBorder: const CircleBorder(),
            child: const Tooltip(
              message: 'ຄົ້ນຫາດ້ວຍສຽງ',
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverBanner extends StatefulWidget {
  @override
  State<_DiscoverBanner> createState() => _DiscoverBannerState();
}

class _DiscoverBannerState extends State<_DiscoverBanner> {
  static const _slideImages = [
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80',
  ];

  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final next = (_page + 1) % _slideImages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _controller,
              itemCount: _slideImages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) =>
                  _BannerSlide(imageUrl: _slideImages[i]),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slideImages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: i == _page ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.accent.withValues(alpha: 0.35),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ຄົ້ນພົບ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ຄົ້ນພົບບ້ານ\nໃໝ່ຂອງທ່ານ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ຊັບສິນທີ່ຢືນຢັນແລ້ວຫລາຍພັນລາຍການ\nທົ່ວປະເທດລາວ.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(14),
                splashColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Text(
                    'ສຳຫຼວດເລີຍ',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ເບິ່ງທັງໝົດ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 110,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _MiniMapPainter()),
                  const Positioned(left: 22, top: 30, child: _MapPin()),
                  const Positioned(left: 58, top: 55, child: _MapPin()),
                  const Positioned(left: 40, top: 70, child: _MapPin()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ຄົ້ນຫາຊັບສິນໃກ້ທ່ານ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ສຳຫຼວດລາຍການເທິງແຜນທີ່ອ້ອມຂ້າງທ່ານ.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 9),
                      child: Center(
                        child: Text(
                          'ເປີດແຜນທີ່',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F3EC);
    canvas.drawRect(Offset.zero & size, bg);

    final block = Paint()..color = const Color(0xFFDCEAE0);
    canvas.drawRect(const Rect.fromLTWH(8, 10, 34, 26), block);
    canvas.drawRect(const Rect.fromLTWH(66, 14, 36, 20), block);
    canvas.drawRect(const Rect.fromLTWH(14, 60, 30, 30), block);
    canvas.drawRect(const Rect.fromLTWH(60, 66, 40, 24), block);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(0, size.height * 0.42),
      Offset(size.width, size.height * 0.38),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.55, size.height),
      road,
    );

    final roadThin = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.82),
      roadThin,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              property.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Text(
                  '${property.formattedPrice} ກີບ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
