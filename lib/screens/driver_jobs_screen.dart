import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/driver_repository.dart';
import '../models/moving_request.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class DriverJobsScreen extends StatefulWidget {
  const DriverJobsScreen({super.key});

  @override
  State<DriverJobsScreen> createState() => _DriverJobsScreenState();
}

class _DriverJobsScreenState extends State<DriverJobsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

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
                    'ວຽກຂົນສົ່ງ',
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
              tabs: const [
                Tab(text: 'ວຽກລໍຖ້າຮັບ'),
                Tab(text: 'ວຽກຂອງຂ້ອຍ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_PendingJobsTab(), _MyJobsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingJobsTab extends StatefulWidget {
  const _PendingJobsTab();

  @override
  State<_PendingJobsTab> createState() => _PendingJobsTabState();
}

class _PendingJobsTabState extends State<_PendingJobsTab> {
  List<MovingRequest> _requests = [];
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
      final requests = await DriverRepository.fetchPendingForDrivers();
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

  Future<void> _accept(MovingRequest request) async {
    setState(() => _busyIds.add(request.id));
    try {
      await DriverRepository.acceptRequest(request);
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
        const SnackBar(content: Text('ຮັບວຽກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
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
              Icons.inbox_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'ຍັງບໍ່ມີວຽກລໍຖ້າຮັບ',
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
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final request = _requests[i];
          return _JobCard(
            request: request,
            busy: _busyIds.contains(request.id),
            primaryLabel: 'ຮັບວຽກ',
            onPrimary: () => _accept(request),
          );
        },
      ),
    );
  }
}

class _MyJobsTab extends StatefulWidget {
  const _MyJobsTab();

  @override
  State<_MyJobsTab> createState() => _MyJobsTabState();
}

class _MyJobsTabState extends State<_MyJobsTab> {
  List<MovingRequest> _jobs = [];
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
      final jobs = await DriverRepository.fetchMyJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
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

  Future<void> _advance(MovingRequest request, String nextStatus) async {
    setState(() => _busyIds.add(request.id));
    try {
      await DriverRepository.updateStatus(request, nextStatus);
      if (!mounted) return;
      _busyIds.remove(request.id);
      await _load();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _busyIds.remove(request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ອັບເດດສະຖານະບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
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
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'ຍັງບໍ່ມີວຽກຂອງທ່ານ',
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
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: _jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final job = _jobs[i];
          final busy = _busyIds.contains(job.id);
          return switch (job.status) {
            'accepted' => _JobCard(
              request: job,
              busy: busy,
              primaryLabel: 'ເລີ່ມຂົນສົ່ງ',
              onPrimary: () => _advance(job, 'in_progress'),
            ),
            'in_progress' => _JobCard(
              request: job,
              busy: busy,
              primaryLabel: 'ສຳເລັດແລ້ວ',
              onPrimary: () => _advance(job, 'completed'),
            ),
            _ => _JobCard(request: job, busy: false),
          };
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.request,
    required this.busy,
    this.primaryLabel,
    this.onPrimary,
  });

  final MovingRequest request;
  final bool busy;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (request.status) {
      'accepted' => ('ຮັບແລ້ວ', const Color(0xFF2563EB)),
      'in_progress' => ('ກຳລັງດຳເນີນການ', AppColors.primaryGreen),
      'completed' => ('ສຳເລັດແລ້ວ', AppColors.textSecondary),
      _ => ('ລໍຖ້າຮັບ', const Color(0xFFD97706)),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.vehicleType,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.trip_origin_rounded,
                size: 13,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.pickupLocation,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 13,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.dropoffLocation,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${request.preferredDate.day}/${request.preferredDate.month}/${request.preferredDate.year}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (request.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.notes,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
          if (primaryLabel != null && onPrimary != null) ...[
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
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onPrimary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          primaryLabel!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
