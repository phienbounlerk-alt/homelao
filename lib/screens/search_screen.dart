import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/property_repository.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/property_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String _query = '';
  String? _activeCategory;
  SearchFilters _filters = const SearchFilters();
  List<String> _locations = [];

  static const _pageSize = 10;
  final List<Property> _results = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _error = false;

  static const _categories = [
    (Icons.apartment_rounded, 'ອາພາດເມັນ'),
    (Icons.bed_rounded, 'ຫ້ອງເຊົ່າ'),
    (Icons.house_rounded, 'ເຮືອນ'),
    (Icons.location_city_rounded, 'ຄອນໂດ'),
    (Icons.holiday_village_rounded, 'ວິນລາ'),
    (Icons.chair_rounded, 'ຫ້ອງການ'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    PropertyRepository.fetchLocations().then((locs) {
      if (mounted) setState(() => _locations = locs);
    });
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loadingInitial) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _results.clear();
        _hasMore = true;
        _loadingInitial = true;
        _error = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await PropertyRepository.fetchPage(
        page: _page,
        pageSize: _pageSize,
        query: _query,
        category: _activeCategory,
        minPrice: _filters.priceRange.start,
        maxPrice: _filters.priceRange.end,
        minBeds: _filters.minBeds,
        location: _filters.location,
      );
      if (!mounted) return;
      setState(() {
        _results.addAll(page);
        _page++;
        _hasMore = page.length == _pageSize;
        _loadingInitial = false;
        _loadingMore = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      if (_results.isEmpty) {
        setState(() {
          _loadingInitial = false;
          _loadingMore = false;
          _error = true;
        });
      } else {
        setState(() {
          _loadingInitial = false;
          _loadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ໂຫລດຂໍ້ມູນເພີ່ມບໍ່ສຳເລັດ')),
        );
      }
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadPage(reset: true),
    );
  }

  void _onCategoryTap(String category) {
    setState(
      () => _activeCategory = _activeCategory == category ? null : category,
    );
    _loadPage(reset: true);
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(
      context,
      initial: _filters,
      locations: _locations,
    );
    if (result != null) {
      setState(() => _filters = result);
      _loadPage(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
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
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _onQueryChanged,
                              decoration: InputDecoration(
                                hintText: 'ຄົ້ນຫາອາພາດເມັນ, ເຮືອນ, ຄອນໂດ...',
                                hintStyle: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _controller.clear();
                                _onQueryChanged('');
                              },
                              child: Tooltip(
                                message: 'ລ້າງຄຳຄົ້ນຫາ',
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _filters.isActive
                        ? AppColors.primaryGreen
                        : AppColors.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openFilters,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Tooltip(
                              message: 'ຕົວກອງ',
                              child: Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: _filters.isActive
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (_filters.isActive)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${_filters.activeCount}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = _activeCategory == c.$2;
                  return Material(
                    color: selected
                        ? AppColors.primaryGreen
                        : AppColors.secondaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onCategoryTap(c.$2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.$1,
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.$2,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _loadingInitial
                        ? 'ກຳລັງຄົ້ນຫາ...'
                        : 'ພົບ ${_results.length}${_hasMore ? '+' : ''} ຊັບສິນ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_filters.isActive) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() => _filters = const SearchFilters());
                        _loadPage(reset: true);
                      },
                      child: Text(
                        'ລ້າງຕົວກອງ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingInitial
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : _error
                  ? ErrorState(onRetry: () => _loadPage(reset: true))
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ບໍ່ພົບຊັບສິນ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ລອງຄົ້ນຫາຄຳອື່ນ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _results.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _results.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: PropertyCard(
                            property: _results[i],
                            width: MediaQuery.of(context).size.width - 40,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
