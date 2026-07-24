import 'dart:async';

import 'package:flutter/material.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/category_item.dart';
import '../widgets/feature_chip.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/location_chip.dart';
import '../widgets/property_card.dart';
import 'messages_screen.dart';
import 'post_listing_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const _categories = [
    (Icons.apartment_rounded, 'Apartment'),
    (Icons.bed_rounded, 'Rental Room'),
    (Icons.house_rounded, 'House'),
    (Icons.location_city_rounded, 'Condo'),
    (Icons.holiday_village_rounded, 'Villa'),
    (Icons.chair_rounded, 'Office'),
    (Icons.map_rounded, 'Land'),
    (Icons.grid_view_rounded, 'More'),
  ];

  static const _features = [
    (Icons.verified_rounded, 'Verified\nListings'),
    (Icons.near_me_rounded, 'Nearby\nRentals'),
    (Icons.sell_rounded, 'Lowest\nPrices'),
    (Icons.chat_bubble_rounded, 'Instant\nChat'),
    (Icons.calendar_month_rounded, 'Book\nViewing'),
    (Icons.calculate_rounded, 'Mortgage\nCalculator'),
    (Icons.local_shipping_rounded, 'Move-in\nServices'),
    (Icons.support_agent_rounded, '24/7\nSupport'),
  ];

  static final _recommended = [
    const Property(
      imageUrl:
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=400&q=80',
      priceLak: 1800000,
      title: 'Modern Apartment Near Patuxay',
      location: 'Chanthabouly, Vientiane',
      beds: 2,
      baths: 1,
      areaSqm: 45,
      rating: 4.8,
      views: 1240,
    ),
    const Property(
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
      priceLak: 1200000,
      title: 'Cozy Room for Rent Fully Furnished',
      location: 'Sisattanak, Vientiane',
      beds: 1,
      baths: 1,
      areaSqm: 25,
      rating: 4.6,
      views: 890,
    ),
    const Property(
      imageUrl:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&q=80',
      priceLak: 2500000,
      title: 'Luxury Condo With City View',
      location: 'Xaysettha, Vientiane',
      beds: 2,
      baths: 2,
      areaSqm: 60,
      rating: 4.9,
      views: 2103,
    ),
  ];

  static const _trendingLocations = [
    (
      'Vientiane',
      'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=100&q=80',
    ),
    (
      'Luang Prabang',
      'https://images.unsplash.com/photo-1528181304800-259b08848526?w=100&q=80',
    ),
    (
      'Pakse',
      'https://images.unsplash.com/photo-1512100356356-de1b84283e18?w=100&q=80',
    ),
    (
      'Savannakhet',
      'https://images.unsplash.com/photo-1500835556837-99ac94a94552?w=100&q=80',
    ),
    (
      'Thakhek',
      'https://images.unsplash.com/photo-1509644851169-2acc08aa25b5?w=100&q=80',
    ),
    (
      'Vang Vieng',
      'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=100&q=80',
    ),
  ];

  static final _recentlyViewed = [
    (
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=200&q=80',
      '1,500,000',
    ),
    (
      'https://images.unsplash.com/photo-1560184897-ae75f418493e?w=200&q=80',
      '2,200,000',
    ),
    (
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=200&q=80',
      '1,000,000',
    ),
    (
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=200&q=80',
      '3,500,000',
    ),
    (
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=200&q=80',
      '1,800,000',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                delegate: _StickySearchBarDelegate(),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (final f in _features.sublist(0, 4))
                              Expanded(
                                child: FeatureChip(icon: f.$1, label: f.$2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (final f in _features.sublist(4, 8))
                              Expanded(
                                child: FeatureChip(icon: f.$1, label: f.$2),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: _SectionHeader(title: 'Recommended for you'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 348,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommended.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, i) =>
                        PropertyCard(property: _recommended[i]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Text(
                    'Trending locations',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _MapCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _SectionHeader(title: 'Recently viewed'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentlyViewed.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final (url, price) = _recentlyViewed[i];
                      return _RecentThumb(imageUrl: url, price: price);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            return;
          }
          if (i == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostListingScreen()),
            );
            return;
          }
          if (i == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
            return;
          }
          if (i == 4) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 22),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Vientiane, Laos',
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: AppColors.textPrimary,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
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
          text: const TextSpan(
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
        const Text(
          'Find your perfect place to live',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
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
      child: const _SearchBar(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(24),
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
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
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Search apartments, houses, condos...',
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
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
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
            child: const SizedBox(
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
        gradient: const LinearGradient(
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
                'DISCOVER',
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
              'Discover Your\nNext Home',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thousands of verified properties\nacross Laos.',
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Text(
                    'Explore Now',
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
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
        color: const Color(0xFFF9FAFB),
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
                const Text(
                  'Find properties near you',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore listings on the map around your location.',
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
                          'Open Interactive Map',
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
  const _RecentThumb({required this.imageUrl, required this.price});

  final String imageUrl;
  final String price;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(imageUrl, width: 96, height: 96, fit: BoxFit.cover),
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
              child: const Icon(
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
                '$price LAK',
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
    );
  }
}
