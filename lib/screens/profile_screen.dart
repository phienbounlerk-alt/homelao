import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'messages_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _menuItems = [
    (Icons.home_work_rounded, 'ລາຍການຂອງຂ້ອຍ'),
    (Icons.favorite_rounded, 'ຊັບສິນທີ່ບັນທຶກ'),
    (Icons.chat_bubble_rounded, 'ຂໍ້ຄວາມ'),
    (Icons.event_available_rounded, 'ປະຫວັດການຈອງ'),
    (Icons.payment_rounded, 'ວິທີການຊຳລະເງິນ'),
    (Icons.settings_rounded, 'ຕັ້ງຄ່າ'),
    (Icons.help_rounded, 'ສູນຊ່ວຍເຫຼືອ'),
  ];

  void _handleTap(BuildContext context, String label) {
    if (label == 'ຂໍ້ຄວາມ') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
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
            child: const Text(
              'ຍົກເລີກ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            Row(
              children: [
                Material(
                  color: const Color(0xFFF9FAFB),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ໂປຼໄຟລ໌',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ສົມສະໜຸກ ພ.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'somsanouk@example.com',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.secondaryGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _handleTap(context, 'ແກ້ໄຂໂປຼໄຟລ໌'),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.primaryGreen,
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
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: _StatItem(value: '3', label: 'ລາຍການ'),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _StatItem(value: '12', label: 'ບັນທຶກ'),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _StatItem(value: '5', label: 'ການຈອງ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
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
                      const Divider(
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
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
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
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
