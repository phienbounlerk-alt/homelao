import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/property_repository.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/property_card.dart';
import 'feature_listing_screen.dart';
import 'post_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Property> _properties = [];
  bool _loading = true;
  bool _error = false;

  /// Property ids with a rent-toggle or renew request in flight — guards
  /// against a rapid double-tap firing two overlapping requests for the
  /// same row (whichever response lands last would otherwise win).
  final Set<String> _pendingActions = {};

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
      final properties = await PropertyRepository.fetchMine();
      if (!mounted) return;
      setState(() {
        _properties = properties;
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

  Future<void> _confirmDelete(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ລຶບປະກາດ'),
        content: Text('ລຶບ "${property.title}" ຖາວອນ? ຈະກູ້ຄືນບໍ່ໄດ້.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'ຍົກເລີກ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'ລຶບ',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PropertyRepository.delete(property.id);
      if (!mounted) return;
      _load();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ລຶບບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  Future<void> _toggleRented(Property property, bool value) async {
    final i = _properties.indexWhere((p) => p.id == property.id);
    if (i == -1 || _pendingActions.contains(property.id)) return;
    setState(() {
      _pendingActions.add(property.id);
      _properties[i] = property.withRented(value);
    });
    try {
      await PropertyRepository.setRented(property.id, value);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _properties[i] = property);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ອັບເດດສະຖານະບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    } finally {
      if (mounted) setState(() => _pendingActions.remove(property.id));
    }
  }

  Future<void> _renew(Property property) async {
    final i = _properties.indexWhere((p) => p.id == property.id);
    if (i == -1 || _pendingActions.contains(property.id)) return;
    setState(() => _pendingActions.add(property.id));
    try {
      final newExpiry = await PropertyRepository.renew(property.id);
      if (!mounted) return;
      setState(() => _properties[i] = property.withExpiry(newExpiry));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຕໍ່ອາຍຸປະກາດແລ້ວ')),
      );
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຕໍ່ອາຍຸບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    } finally {
      if (mounted) setState(() => _pendingActions.remove(property.id));
    }
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
                          padding: EdgeInsets.all(10),
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
                    'ລາຍການຂອງຂ້ອຍ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : _error
                  ? ErrorState(onRetry: _load)
                  : _properties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ຍັງບໍ່ໄດ້ລົງປະກາດຊັບສິນ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ກົດ "+" ດ້ານລຸ່ມເພື່ອລົງປະກາດຊັບສິນທຳອິດ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _properties.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final property = _properties[i];
                        final cardWidth =
                            MediaQuery.of(context).size.width - 40;
                        final photoHeight = cardWidth * 9 / 16;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                PropertyCard(
                                  property: property,
                                  width: cardWidth,
                                ),
                                if (property.status != 'approved')
                                  // Bottom-left of the photo: the verified
                                  // badge already owns top-left and the
                                  // favorite icon owns top-right.
                                  Positioned(
                                    left: 10,
                                    top: photoHeight - 32,
                                    child: _StatusBadge(
                                      status: property.status,
                                    ),
                                  ),
                              ],
                            ),
                            if (property.status == 'rejected')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PostListingScreen(
                                                      existing: property,
                                                    ),
                                              ),
                                            )
                                            .then((_) => _load()),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryGreen,
                                          side: BorderSide(
                                            color: AppColors.primaryGreen,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'ແກ້ໄຂ',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _confirmDelete(property),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'ລຶບ',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (property.status == 'approved') ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      property.isRented
                                          ? 'ເຊົ່າແລ້ວ'
                                          : 'ຫ້ອງວ່າງ',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: property.isRented
                                            ? AppColors.primaryGreen
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    Switch(
                                      value: property.isRented,
                                      onChanged:
                                          _pendingActions.contains(
                                            property.id,
                                          )
                                          ? null
                                          : (v) =>
                                                _toggleRented(property, v),
                                      activeThumbColor: AppColors.primaryGreen,
                                    ),
                                    const Spacer(),
                                    if (property.expiresAt != null)
                                      _ExpiryLabel(
                                        expiresAt: property.expiresAt!,
                                      ),
                                    TextButton(
                                      onPressed:
                                          _pendingActions.contains(
                                            property.id,
                                          )
                                          ? null
                                          : () => _renew(property),
                                      child: Text(
                                        'ຕໍ່ອາຍຸ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PostListingScreen(
                                                    existing: property,
                                                  ),
                                            ),
                                          )
                                          .then((_) => _load()),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primaryGreen,
                                        side: BorderSide(
                                          color: AppColors.primaryGreen,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'ແກ້ໄຂ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(property),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'ລຶບ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: property.isFeaturedNow
                                    ? Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ເດັ່ນຢູ່ຮອດ ${property.featuredUntil!.day}/${property.featuredUntil!.month}/${property.featuredUntil!.year}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      )
                                    : InkWell(
                                        onTap: () => Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FeatureListingScreen(
                                                      property: property,
                                                    ),
                                              ),
                                            )
                                            .then((_) => _load()),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_outline_rounded,
                                              size: 16,
                                              color: AppColors.primaryGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'ເຮັດໃຫ້ເດັ່ນ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ],
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

class _ExpiryLabel extends StatelessWidget {
  const _ExpiryLabel({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    final expiringSoon = daysLeft <= 7;
    return Text(
      daysLeft <= 0
          ? 'ໝົດອາຍຸແລ້ວ'
          : 'ໝົດອາຍຸໃນ $daysLeft ວັນ',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: expiringSoon ? Colors.redAccent : AppColors.textSecondary,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: rejected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rejected ? 'ຖືກປະຕິເສດ' : 'ລໍຖ້າອະນຸມັດ',
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
