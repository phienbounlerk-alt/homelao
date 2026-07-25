import 'package:flutter/material.dart';
import '../data/property_repository.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/property_card.dart';
import 'feature_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Property> _properties = [];
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
      final properties = await PropertyRepository.fetchMine();
      if (!mounted) return;
      setState(() {
        _properties = properties;
        _loading = false;
      });
    } catch (_) {
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
                            if (property.status == 'approved')
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
