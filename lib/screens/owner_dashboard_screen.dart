import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/owner_dashboard_repository.dart';
import '../models/daily_event.dart';
import '../models/owner_dashboard_summary.dart';
import '../theme/app_theme.dart';
import 'post_listing_screen.dart';

enum _ChartMetric { views, favorites, phoneClicks, messages, bookings }

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  OwnerDashboardSummary? _summary;
  List<DailyEvent> _daily = [];
  bool _loading = true;
  bool _error = false;
  ChartPeriod _period = ChartPeriod.daily;
  _ChartMetric _metric = _ChartMetric.views;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait([
        OwnerDashboardRepository.fetchSummary(),
        OwnerDashboardRepository.fetchDailyEvents(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as OwnerDashboardSummary;
        _daily = results[1] as List<DailyEvent>;
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
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Tooltip(
                        message: 'ກັບຄືນ',
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ແດຊບອດເຈົ້າຂອງ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) {
      return _MessageState(
        icon: Icons.error_outline_rounded,
        title: 'ໂຫຼດຂໍ້ມູນບໍ່ສຳເລັດ',
        subtitle: 'ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
        actionLabel: 'ລອງໃໝ່',
        onAction: _load,
      );
    }
    final summary = _summary!;
    if (summary.totalListings == 0) {
      return _MessageState(
        icon: Icons.bar_chart_rounded,
        title: 'ຍັງບໍ່ໄດ້ລົງປະກາດຊັບສິນ',
        subtitle: 'ລົງປະກາດຊັບສິນທຳອິດ ເພື່ອເລີ່ມເບິ່ງສະຖິຕິ',
        actionLabel: 'ລົງປະກາດ',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PostListingScreen()),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KpiGrid(summary: summary),
            const SizedBox(height: 24),
            Text(
              'ແນວໂນ້ມກິດຈະກຳ',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _PeriodToggle(
              period: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 8),
            _MetricToggle(
              metric: _metric,
              onChanged: (m) => setState(() => _metric = m),
            ),
            const SizedBox(height: 12),
            _TrendChart(
              data: OwnerDashboardRepository.resample(_daily, _period),
              metric: _metric,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final OwnerDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('ຍອດເຂົ້າເບິ່ງ', '${summary.totalViews}', Icons.visibility_rounded),
      (
        'ຊັບສິນທີ່ຖືກບັນທຶກ',
        '${summary.totalFavorites}',
        Icons.favorite_rounded,
      ),
      ('ການໂທ', '${summary.totalPhoneClicks}', Icons.call_rounded),
      ('ຂໍ້ຄວາມ', '${summary.totalMessages}', Icons.chat_bubble_rounded),
      (
        'ການນັດເບິ່ງຫ້ອງ',
        '${summary.totalBookings}',
        Icons.event_available_rounded,
      ),
      (
        'ລາຍໄດ້ໂດຍປະມານ/ເດືອນ',
        '${summary.estimatedMonthlyRevenue.toLakString()} ກີບ',
        Icons.payments_rounded,
      ),
      (
        'ອັດຕາການເຊົ່າ',
        '${summary.occupancyRate.toStringAsFixed(0)}%',
        Icons.pie_chart_rounded,
      ),
      (
        'ຄະແນນສະເລ່ຍ',
        summary.avgRating.toStringAsFixed(1),
        Icons.star_rounded,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (final c in cards)
          _KpiCard(label: c.$1, value: c.$2, icon: c.$3),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onChanged;

  static const _labels = {
    ChartPeriod.daily: 'ວັນ',
    ChartPeriod.weekly: 'ອາທິດ',
    ChartPeriod.monthly: 'ເດືອນ',
    ChartPeriod.yearly: 'ປີ',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in ChartPeriod.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: _labels[p]!,
              selected: p == period,
              onTap: () => onChanged(p),
            ),
          ),
      ],
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({required this.metric, required this.onChanged});

  final _ChartMetric metric;
  final ValueChanged<_ChartMetric> onChanged;

  static const _labels = {
    _ChartMetric.views: 'ຍອດເຂົ້າເບິ່ງ',
    _ChartMetric.favorites: 'ບັນທຶກ',
    _ChartMetric.phoneClicks: 'ການໂທ',
    _ChartMetric.messages: 'ຂໍ້ຄວາມ',
    _ChartMetric.bookings: 'ນັດເບິ່ງ',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final m in _ChartMetric.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: _labels[m]!,
                selected: m == metric,
                onTap: () => onChanged(m),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryGreen : AppColors.secondaryGreen,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data, required this.metric});

  final List<DailyEvent> data;
  final _ChartMetric metric;

  int _valueOf(DailyEvent e) => switch (metric) {
    _ChartMetric.views => e.views,
    _ChartMetric.favorites => e.favorites,
    _ChartMetric.phoneClicks => e.phoneClicks,
    _ChartMetric.messages => e.messages,
    _ChartMetric.bookings => e.bookings,
  };

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'ຍັງບໍ່ມີຂໍ້ມູນ',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
      );
    }
    // Newest-first from the repository — render oldest-first, left to right.
    final ordered = data.reversed.toList();
    final maxValue = ordered
        .map(_valueOf)
        .fold(1, (max, v) => v > max ? v : max);
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in ordered)
            Expanded(
              child: Tooltip(
                message: '${e.day.month}/${e.day.day}: ${_valueOf(e)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (_valueOf(e) / maxValue).clamp(0.04, 1.0),
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, heightFactor, _) =>
                        FractionallySizedBox(
                          heightFactor: heightFactor,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Colors.white,
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

extension on int {
  /// Comma-grouped thousands, matching Property.formattedPrice's style.
  String toLakString() {
    final s = toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
