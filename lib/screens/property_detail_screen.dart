import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../data/analytics_repository.dart';
import '../data/conversation_repository.dart';
import '../data/favorites_store.dart';
import '../data/property_repository.dart';
import '../data/review_repository.dart';
import '../models/property.dart';
import '../models/review.dart';
import '../models/review_summary.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_sheet.dart';
import '../widgets/property_card.dart';
import '../widgets/review_card.dart';
import '../widgets/review_summary_card.dart';
import 'messages_screen.dart';
import 'review_form_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _photoController = PageController();
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.addListener(_onFavoritesChanged);
    AnalyticsRepository.track('property_viewed', {
      'property_id': widget.property.id,
    });
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_onFavoritesChanged);
    _photoController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(String propertyId) async {
    final succeeded = await FavoritesStore.instance.toggle(propertyId);
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ບັນທຶກບໍ່ສຳເລັດ — ກະລຸນາລອງໃໝ່')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isFavorite = FavoritesStore.instance.isFavorite(property.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: PageView.builder(
                          controller: _photoController,
                          itemCount: property.displayPhotos.length,
                          onPageChanged: (i) =>
                              setState(() => _photoIndex = i),
                          itemBuilder: (context, i) => Image.network(
                            property.displayPhotos[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (property.displayPhotos.length > 1)
                        Positioned(
                          bottom: property.verified ? 52 : 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  property.displayPhotos.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: i == _photoIndex ? 16 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: i == _photoIndex ? 1 : 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RoundIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                tooltip: 'ກັບຄືນ',
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              _RoundIconButton(
                                icon: isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                iconColor: isFavorite
                                    ? Colors.redAccent
                                    : AppColors.textPrimary,
                                tooltip: isFavorite
                                    ? 'ຍົກເລີກບັນທຶກ'
                                    : 'ບັນທຶກຊັບສິນ',
                                onTap: () => _toggleFavorite(property.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (property.verified)
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ຢືນຢັນແລ້ວ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${property.formattedPrice} ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            Text(
                              'ກີບ/ເດືອນ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          property.title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.location,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.bed_outlined,
                                  value: '${property.beds}',
                                  label: 'ຫ້ອງນອນ',
                                ),
                              ),
                              _StatDivider(),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.bathtub_outlined,
                                  value: '${property.baths}',
                                  label: 'ຫ້ອງນ້ຳ',
                                ),
                              ),
                              _StatDivider(),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.aspect_ratio,
                                  value: '${property.areaSqm}',
                                  label: 'ຕມ.',
                                ),
                              ),
                              _StatDivider(),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.star,
                                  iconColor: AppColors.success,
                                  value: '${property.rating}',
                                  label: 'ຄະແນນ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ລາຍລະອຽດ',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          property.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ເຈົ້າຂອງຊັບສິນ',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  property.landlordAvatarUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.landlordName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (property.verified) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: AppColors.primaryGreen,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'ເຈົ້າຂອງຢືນຢັນແລ້ວ',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ReviewsSection(property: property),
                        _SimilarPropertiesSection(property: property),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: AppColors.secondaryGreen,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => showBookingSheet(context, property),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: Text(
                              'ນັດເບິ່ງບ້ານ',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final conversationId =
                              await ConversationRepository.findOrCreate(
                                propertyId: property.id,
                                landlordName: property.landlordName,
                                landlordAvatarUrl: property.landlordAvatarUrl,
                              );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversationId: conversationId,
                                name: property.landlordName,
                                avatarUrl: property.landlordAvatarUrl,
                                propertyTitle: property.title,
                                propertyImageUrl: property.imageUrl,
                                propertyPriceLak: property.priceLak,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: Text(
                              'ແຊັດເຈົ້າຂອງ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Other listings that resemble this one — same district, similar price,
/// or the same bed count (see PropertyRepository.fetchSimilar). Not a
/// learned recommendation; quietly hides itself if nothing matches rather
/// than showing an empty section.
class _SimilarPropertiesSection extends StatefulWidget {
  const _SimilarPropertiesSection({required this.property});

  final Property property;

  @override
  State<_SimilarPropertiesSection> createState() =>
      _SimilarPropertiesSectionState();
}

class _SimilarPropertiesSectionState
    extends State<_SimilarPropertiesSection> {
  List<Property>? _similar;

  @override
  void initState() {
    super.initState();
    PropertyRepository.fetchSimilar(widget.property)
        .then((results) {
          if (mounted) setState(() => _similar = results);
        })
        .catchError((Object e, StackTrace st) {
          Sentry.captureException(e, stackTrace: st);
          if (mounted) setState(() => _similar = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final similar = _similar;
    if (similar == null || similar.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ຊັບສິນທີ່ຄ້າຍຄືກັນ',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: similar.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => PropertyCard(property: similar[i]),
            ),
          ),
        ],
      ),
    );
  }
}

const _sortLabels = {
  ReviewSort.latest: 'ຫຼ້າສຸດ',
  ReviewSort.highest: 'ຄະແນນສູງສຸດ',
  ReviewSort.lowest: 'ຄະແນນຕ່ຳສຸດ',
  ReviewSort.mostHelpful: 'ເປັນປະໂຫຍດທີ່ສຸດ',
};

/// Eligibility-aware entry point into the review flow (write / edit / not
/// yet eligible), plus the public rating summary, sortable review list,
/// and the cards themselves.
class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.property});

  final Property property;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  Review? _myReview;
  bool _canReview = false;
  bool _loading = true;

  ReviewSummary? _summary;
  List<Review>? _reviews;
  ReviewSort _sort = ReviewSort.latest;

  @override
  void initState() {
    super.initState();
    _load();
    _loadReviews();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ReviewRepository.fetchMyReview(widget.property.id),
        ReviewRepository.hasBookedProperty(widget.property.id),
      ]);
      if (!mounted) return;
      setState(() {
        _myReview = results[0] as Review?;
        _canReview = results[1] as bool;
        _loading = false;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final results = await Future.wait([
        ReviewRepository.fetchSummary(widget.property.id),
        ReviewRepository.fetchForProperty(widget.property.id, sort: _sort),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as ReviewSummary;
        _reviews = results[1] as List<Review>;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _reviews = const []);
    }
  }

  void _changeSort(ReviewSort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _loadReviews();
  }

  Future<void> _openForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          property: widget.property,
          existing: _myReview,
        ),
      ),
    );
    if (saved == true) {
      _load();
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final reviews = _reviews;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ຣີວິວ',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const SizedBox.shrink()
          else if (_myReview != null)
            _ReviewCtaButton(
              icon: Icons.edit_rounded,
              label: 'ແກ້ໄຂຣີວິວຂອງທ່ານ',
              onTap: _openForm,
            )
          else if (_canReview)
            _ReviewCtaButton(
              icon: Icons.star_rounded,
              label: 'ຂຽນຣີວິວ',
              onTap: _openForm,
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ນັດເບິ່ງຫ້ອງກ່ອນຈຶ່ງຈະຂຽນຣີວິວໄດ້',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (summary != null && summary.reviewCount > 0) ...[
            const SizedBox(height: 16),
            ReviewSummaryCard(summary: summary),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${summary.reviewCount} ຣີວິວ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                PopupMenuButton<ReviewSort>(
                  initialValue: _sort,
                  onSelected: _changeSort,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (context) => [
                    for (final entry in _sortLabels.entries)
                      PopupMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: entry.key == _sort
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: entry.key == _sort
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _sortLabels[_sort]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (reviews != null)
              Column(
                children: [
                  for (var i = 0; i < reviews.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == reviews.length - 1 ? 0 : 12,
                      ),
                      child: ReviewCard(review: reviews[i]),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCtaButton extends StatelessWidget {
  const _ReviewCtaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryGreen,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    // Sits on a white circle over the hero photo, so the icon stays a fixed
    // dark tone regardless of app theme rather than following AppColors.
    this.iconColor = const Color(0xFF111827),
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.primaryGreen),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.cardBorder);
  }
}
