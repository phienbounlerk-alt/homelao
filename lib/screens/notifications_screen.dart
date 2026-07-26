import 'package:flutter/material.dart';
import '../data/notification_repository.dart';
import '../data/property_repository.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';
import 'property_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final _stream = NotificationRepository.streamMine();

  Future<void> _openNotification(AppNotification n) async {
    if (!n.read) NotificationRepository.markRead(n.id);
    final propertyId = n.relatedPropertyId;
    if (propertyId == null) return;
    try {
      final property = await PropertyRepository.fetchById(propertyId);
      if (!mounted || property == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property),
        ),
      );
    } catch (_) {
      // Property may have been deleted since — nothing to open.
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ຫາກໍ່ນີ້';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີກ່ອນ';
    if (diff.inHours < 24) return '${diff.inHours} ຊົ່ວໂມງກ່ອນ';
    return '${diff.inDays} ວັນກ່ອນ';
  }

  IconData _iconFor(String type) => switch (type) {
    'listing_approved' => Icons.check_circle_rounded,
    'listing_rejected' => Icons.cancel_rounded,
    'feature_confirmed' => Icons.star_rounded,
    'feature_rejected' => Icons.star_outline_rounded,
    'driver_approved' => Icons.check_circle_rounded,
    'driver_rejected' => Icons.cancel_rounded,
    'moving_accepted' => Icons.local_shipping_rounded,
    'moving_in_progress' => Icons.local_shipping_rounded,
    'moving_completed' => Icons.check_circle_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _colorFor(String type) => switch (type) {
    'listing_approved' => AppColors.primaryGreen,
    'listing_rejected' => const Color(0xFFDC2626),
    'feature_confirmed' => const Color(0xFFD97706),
    'feature_rejected' => const Color(0xFFDC2626),
    'driver_approved' => AppColors.primaryGreen,
    'driver_rejected' => const Color(0xFFDC2626),
    'moving_accepted' => AppColors.primaryGreen,
    'moving_in_progress' => AppColors.primaryGreen,
    'moving_completed' => AppColors.primaryGreen,
    // Anything unmapped falls back to a neutral color rather than green,
    // so a future notification type can't accidentally read as "good news"
    // by default the way rejections did before this fix.
    _ => AppColors.textSecondary,
  };

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
                    'ແຈ້ງເຕືອນ',
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
              child: StreamBuilder<List<AppNotification>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  }
                  final notifications = snapshot.data!;
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ຍັງບໍ່ມີແຈ້ງເຕືອນ',
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return Material(
                        color: n.read
                            ? AppColors.surface
                            : AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openNotification(n),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _iconFor(n.type),
                                  size: 22,
                                  color: _colorFor(n.type),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        n.body,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _timeAgo(n.createdAt),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
