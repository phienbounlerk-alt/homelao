import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/admin_repository.dart';
import '../data/favorites_store.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'booking_history_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'legal_screen.dart';
import 'login_screen.dart';
import 'my_listings_screen.dart';
import 'payment_methods_screen.dart';
import 'saved_properties_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onNavigate});

  /// Switches the parent shell's active tab, using the same index scheme
  /// as [HomeBottomNav].
  final ValueChanged<int> onNavigate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _myCount;
  int? _savedCount;
  int? _bookingCount;
  bool _isAdmin = false;

  static const _baseMenuItems = [
    (Icons.home_work_rounded, 'ລາຍການຂອງຂ້ອຍ'),
    (Icons.favorite_rounded, 'ຊັບສິນທີ່ບັນທຶກ'),
    (Icons.chat_bubble_rounded, 'ຂໍ້ຄວາມ'),
    (Icons.event_available_rounded, 'ປະຫວັດການຈອງ'),
    (Icons.payment_rounded, 'ວິທີການຊຳລະເງິນ'),
    (Icons.settings_rounded, 'ຕັ້ງຄ່າ'),
    (Icons.help_rounded, 'ສູນຊ່ວຍເຫຼືອ'),
    (Icons.gavel_rounded, 'ເງື່ອນໄຂ ແລະ ຄວາມເປັນສ່ວນຕົວ'),
  ];

  List<(IconData, String)> get _menuItems => [
    for (final item in _baseMenuItems) ...[
      if (_isAdmin && item.$2 == 'ຕັ້ງຄ່າ')
        (Icons.admin_panel_settings_rounded, 'ຈັດການລະບົບ'),
      item,
    ],
  ];

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.addListener(_onFavoritesChanged);
    _loadStats();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await AdminRepository.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() => _savedCount = FavoritesStore.instance.count);
  }

  Future<void> _loadStats() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('properties').select('id').eq('owner_id', userId),
        client.from('favorites').select('property_id').eq('user_id', userId),
        client.from('bookings').select('id').eq('user_id', userId),
      ]);
      if (!mounted) return;
      setState(() {
        _myCount = (results[0] as List).length;
        _savedCount = (results[1] as List).length;
        _bookingCount = (results[2] as List).length;
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      // Leave counts at their loading placeholder on failure.
    }
  }

  void _handleTap(BuildContext context, String label) {
    if (label == 'ຂໍ້ຄວາມ') {
      widget.onNavigate(3);
      return;
    }
    if (label == 'ລາຍການຂອງຂ້ອຍ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MyListingsScreen()));
      return;
    }
    if (label == 'ຊັບສິນທີ່ບັນທຶກ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
      return;
    }
    if (label == 'ປະຫວັດການຈອງ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
      return;
    }
    if (label == 'ວິທີການຊຳລະເງິນ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
      return;
    }
    if (label == 'ຈັດການລະບົບ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
      return;
    }
    if (label == 'ຕັ້ງຄ່າ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }
    if (label == 'ສູນຊ່ວຍເຫຼືອ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
      return;
    }
    if (label == 'ເງື່ອນໄຂ ແລະ ຄວາມເປັນສ່ວນຕົວ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LegalScreen()));
      return;
    }
    if (label == 'ແກ້ໄຂໂປຼໄຟລ໌') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))
          .then((_) {
            if (mounted) setState(() {});
          });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — ກຳລັງພັດທະນາ')));
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ອອກຈາກລະບົບ'),
        content: const Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ຍົກເລີກ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              FavoritesStore.instance.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'ອອກຈາກລະບົບ',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'ໂປຼໄຟລ໌',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.secondaryGreen,
                  backgroundImage: NetworkImage(
                    Supabase
                                .instance
                                .client
                                .auth
                                .currentUser
                                ?.userMetadata?['avatar_url']
                            as String? ??
                        defaultAvatarUrl,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final user = Supabase.instance.client.auth.currentUser;
                      final isAnon = user?.isAnonymous ?? true;
                      final name = isAnon
                          ? 'ແຂກ'
                          : (user?.userMetadata?['name'] as String?)
                                    ?.isNotEmpty ==
                                true
                          ? user!.userMetadata!['name'] as String
                          : (user?.email ?? 'ແຂກ');
                      final subtitle = isAnon
                          ? 'ເຂົ້າໃຊ້ແບບບໍ່ຕ້ອງລົງທະບຽນ'
                          : (user?.email ?? '');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Material(
                  color: AppColors.secondaryGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _handleTap(context, 'ແກ້ໄຂໂປຼໄຟລ໌'),
                    child: Tooltip(
                      message: 'ແກ້ໄຂໂປຼໄຟລ໌',
                      child: Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
                      value: _myCount?.toString() ?? '—',
                      label: 'ລາຍການ',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _StatItem(
                      value: _savedCount?.toString() ?? '—',
                      label: 'ບັນທຶກ',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _StatItem(
                      value: _bookingCount?.toString() ?? '—',
                      label: 'ການຈອງ',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _menuItems.length; i++) ...[
                    _MenuTile(
                      icon: _menuItems[i].$1,
                      label: _menuItems[i].$2,
                      onTap: () => _handleTap(context, _menuItems[i].$2),
                    ),
                    if (i != _menuItems.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.cardBorder,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _confirmLogout(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ອອກຈາກລະບົບ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
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
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.cardBorder);
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
