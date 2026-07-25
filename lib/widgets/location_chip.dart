import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.imageUrl,
    required this.name,
    this.onTap,
  });

  final String imageUrl;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(30),
      shadowColor: Colors.black.withValues(alpha: 0.06),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.only(right: 12, left: 6, top: 6, bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 14, backgroundImage: NetworkImage(imageUrl)),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
