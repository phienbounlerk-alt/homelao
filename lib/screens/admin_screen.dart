import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/admin_repository.dart';
import '../data/analytics_repository.dart';
import '../models/driver.dart';
import '../models/featured_request.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
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
                    'ຈັດການລະບົບ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryGreen,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'ປະກາດລໍຖ້າອະນຸມັດ'),
                Tab(text: 'ຄຳຮ້ອງເດັ່ນ'),
                Tab(text: 'ຄົນຂັບ'),
                Tab(text: 'ສະຖິຕິ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PendingPropertiesTab(),
                  _FeatureRequestsTab(),
                  _PendingDriversTab(),
                  _AnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPropertiesTab extends StatefulWidget {
  const _PendingPropertiesTab();

  @override
  State<_PendingPropertiesTab> createState() => _PendingPropertiesTabState();
}

class _PendingPropertiesTabState extends State<_PendingPropertiesTab> {
  List<Property> _pending = [];
  bool _loading = true;
  bool _error = false;
  final Set<String> _busyIds = {};

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
      final properties = await AdminRepository.fetchPendingProperties();
      if (!mounted) return;
      setState(() {
        _pending = properties;
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

  Future<void> _decide(Property property, String status) async {
    setState(() => _busyIds.add(property.id));
    try {
      await AdminRepository.setStatus(property, status);
      if (!mounted) return;
      setState(() {
        _pending.removeWhere((p) => p.id == property.id);
        _busyIds.remove(property.id);
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _busyIds.remove(property.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ດຳເນີນການບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'ບໍ່ມີປະກາດລໍຖ້າອະນຸມັດ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final property = _pending[i];
        final busy = _busyIds.contains(property.id);
        return _PendingCard(
          property: property,
          busy: busy,
          onApprove: () => _decide(property, 'approved'),
          onReject: () => _decide(property, 'rejected'),
        );
      },
    );
  }
}

class _FeatureRequestsTab extends StatefulWidget {
  const _FeatureRequestsTab();

  @override
  State<_FeatureRequestsTab> createState() => _FeatureRequestsTabState();
}

class _FeatureRequestsTabState extends State<_FeatureRequestsTab> {
  List<FeaturedRequest> _requests = [];
  bool _loading = true;
  bool _error = false;
  final Set<String> _busyIds = {};

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
      final requests = await AdminRepository.fetchPendingFeatureRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _decide(FeaturedRequest request, bool approve) async {
    setState(() => _busyIds.add(request.id));
    try {
      await AdminRepository.reviewFeatureRequest(
        request: request,
        approve: approve,
      );
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
        _busyIds.remove(request.id);
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _busyIds.remove(request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ດຳເນີນການບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'ບໍ່ມີຄຳຮ້ອງລໍຖ້າກວດສອບ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final request = _requests[i];
        final busy = _busyIds.contains(request.id);
        return _FeatureRequestCard(
          request: request,
          busy: busy,
          onApprove: () => _decide(request, true),
          onReject: () => _decide(request, false),
        );
      },
    );
  }
}

class _PendingDriversTab extends StatefulWidget {
  const _PendingDriversTab();

  @override
  State<_PendingDriversTab> createState() => _PendingDriversTabState();
}

class _PendingDriversTabState extends State<_PendingDriversTab> {
  List<Driver> _pending = [];
  bool _loading = true;
  bool _error = false;
  final Set<String> _busyIds = {};

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
      final drivers = await AdminRepository.fetchPendingDrivers();
      if (!mounted) return;
      setState(() {
        _pending = drivers;
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

  Future<void> _decide(Driver driver, String status) async {
    setState(() => _busyIds.add(driver.id));
    try {
      await AdminRepository.setDriverStatus(driver, status);
      if (!mounted) return;
      setState(() {
        _pending.removeWhere((d) => d.id == driver.id);
        _busyIds.remove(driver.id);
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _busyIds.remove(driver.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ດຳເນີນການບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'ບໍ່ມີຄົນຂັບລໍຖ້າອະນຸມັດ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final driver = _pending[i];
        final busy = _busyIds.contains(driver.id);
        return _DriverCard(
          driver: driver,
          busy: busy,
          onApprove: () => _decide(driver, 'approved'),
          onReject: () => _decide(driver, 'rejected'),
        );
      },
    );
  }
}

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  List<({DateTime day, int events, int users})> _daily = [];
  List<(Property, int)> _topProperties = [];
  List<(String, int)> _topSearches = [];
  bool _loading = true;
  bool _error = false;

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
        AnalyticsRepository.dailyCounts(daysBack: 14),
        AnalyticsRepository.topProperties(daysBack: 7),
        AnalyticsRepository.topSearches(daysBack: 7),
      ]);
      if (!mounted) return;
      setState(() {
        _daily = results[0] as List<({DateTime day, int events, int users})>;
        _topProperties = results[1] as List<(Property, int)>;
        _topSearches = results[2] as List<(String, int)>;
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
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error) return ErrorState(onRetry: _load);

    final today = DateTime.now();
    final todayCount = _daily
        .where(
          (d) =>
              d.day.year == today.year &&
              d.day.month == today.month &&
              d.day.day == today.day,
        )
        .fold(0, (sum, d) => sum + d.events);
    final weekEvents = _daily.take(7).fold(0, (sum, d) => sum + d.events);
    final weekUsers = _daily
        .take(7)
        .map((d) => d.users)
        .fold(0, (max, u) => u > max ? u : max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'ມື້ນີ້', value: '$todayCount'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(label: '7 ວັນຫຼ້າສຸດ', value: '$weekEvents'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(label: 'ຜູ້ໃຊ້ສູງສຸດ/ວັນ', value: '$weekUsers'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'ກິດຈະກຳ 14 ວັນຫຼ້າສຸດ',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _DailyBarChart(daily: _daily),
        const SizedBox(height: 24),
        Text(
          'ຊັບສິນທີ່ຖືກເບິ່ງຫຼາຍສຸດ (7 ວັນ)',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (_topProperties.isEmpty)
          _EmptyStatRow(label: 'ຍັງບໍ່ມີຂໍ້ມູນ')
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _topProperties.length; i++) ...[
                  _RankRow(
                    label: _topProperties[i].$1.title,
                    count: _topProperties[i].$2,
                    unit: 'ຄັ້ງ',
                  ),
                  if (i != _topProperties.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.cardBorder,
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'ຄຳຄົ້ນຫາຍອດນິຍົມ (7 ວັນ)',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (_topSearches.isEmpty)
          _EmptyStatRow(label: 'ຍັງບໍ່ມີຂໍ້ມູນ')
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _topSearches.length; i++) ...[
                  _RankRow(
                    label: _topSearches[i].$1,
                    count: _topSearches[i].$2,
                    unit: 'ຄັ້ງ',
                  ),
                  if (i != _topSearches.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.cardBorder,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.daily});

  final List<({DateTime day, int events, int users})> daily;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return _EmptyStatRow(label: 'ຍັງບໍ່ມີຂໍ້ມູນ');
    // daily arrives newest-first; render oldest-first, left to right.
    final ordered = daily.reversed.toList();
    final maxEvents = ordered
        .map((d) => d.events)
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
          for (final d in ordered)
            Expanded(
              child: Tooltip(
                message: '${d.day.month}/${d.day.day}: ${d.events} events',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: (d.events / maxEvents).clamp(0.04, 1.0),
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
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.label, required this.count, this.unit = ''});

  final String label;
  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count $unit',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatRow extends StatelessWidget {
  const _EmptyStatRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.property,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Property property;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  property.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.formattedPrice} ກີບ/ເດືອນ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'ປະຕິເສດ',
                    color: const Color(0xFFDC2626),
                    onTap: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'ອະນຸມັດ',
                    color: AppColors.primaryGreen,
                    onTap: onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureRequestCard extends StatelessWidget {
  const _FeatureRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final FeaturedRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.proofImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    request.proofImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.propertyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.amountLak} ກີບ — ${request.durationDays} ວັນ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    if (request.proofImageUrl == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'ບໍ່ມີຫຼັກຖານແນບມາ',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'ປະຕິເສດ',
                    color: const Color(0xFFDC2626),
                    onTap: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'ຢືນຢັນການໂອນ',
                    color: AppColors.primaryGreen,
                    onTap: onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Driver driver;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (driver.vehiclePhotoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    driver.vehiclePhotoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver.vehicleType} — ${driver.vehiclePlate}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'ປະຕິເສດ',
                    color: const Color(0xFFDC2626),
                    onTap: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'ອະນຸມັດ',
                    color: AppColors.primaryGreen,
                    onTap: onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
