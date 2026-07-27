import 'package:flutter/material.dart';
import '../models/review_summary.dart';
import '../theme/app_theme.dart';

/// The big-number average, star-distribution bar chart, and per-category
/// averages for a property's reviews — computed server-side by
/// ReviewRepository.fetchSummary rather than derived from the review list.
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({super.key, required this.summary});

  final ReviewSummary summary;

  static const _categories = [
    ('ຄວາມສະອາດ', Icons.cleaning_services_outlined),
    ('ທຳເລທີ່ຕັ້ງ', Icons.location_on_outlined),
    ('ຄວາມປອດໄພ', Icons.shield_outlined),
    ('ອິນເຕີເນັດ', Icons.wifi_rounded),
    ('ບ່ອນຈອດລົດ', Icons.local_parking_outlined),
    ('ຄຸ້ມຄ່າເງິນ', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final averages = [
      summary.avgCleanliness,
      summary.avgLocation,
      summary.avgSafety,
      summary.avgInternet,
      summary.avgParking,
      summary.avgValue,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: summary.avgOverall),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < summary.avgOverall.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 15,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.reviewCount} ຣີວິວ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _DistributionRow(stars: 5, count: summary.star5, max: summary.maxStarBucket),
                    _DistributionRow(stars: 4, count: summary.star4, max: summary.maxStarBucket),
                    _DistributionRow(stars: 3, count: summary.star3, max: summary.maxStarBucket),
                    _DistributionRow(stars: 2, count: summary.star2, max: summary.maxStarBucket),
                    _DistributionRow(stars: 1, count: summary.star1, max: summary.maxStarBucket),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _categories.length; i++)
                SizedBox(
                  width: 148,
                  child: Row(
                    children: [
                      Icon(
                        _categories[i].$2,
                        size: 15,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _categories[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        averages[i].toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.stars,
    required this.count,
    required this.max,
  });

  final int stars;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: AppColors.surfaceAlt),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value.clamp(0, 1),
                        alignment: Alignment.centerLeft,
                        child: Container(color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
