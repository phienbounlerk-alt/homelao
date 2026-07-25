import 'package:flutter/material.dart';
import '../data/analytics_repository.dart';
import '../data/conversation_repository.dart';
import '../data/favorites_store.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_sheet.dart';
import 'messages_screen.dart';

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
                                onTap: () =>
                                    FavoritesStore.instance.toggle(property.id),
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
                                ),
                              ),
                            ],
                          ),
                        ),
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
