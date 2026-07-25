import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.secondaryGreen,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.primaryGreen.withValues(alpha: 0.25),
            highlightColor: AppColors.primaryGreen.withValues(alpha: 0.12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: AppColors.primaryGreen, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
