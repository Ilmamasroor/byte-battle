import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Shared bottom navigation bar (Home / Learn / Battles / Practice /
/// Profile) used across dashboard, curriculum and concept screens.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.menu_book_rounded, label: 'Learn'),
    (icon: Icons.emoji_events_rounded, label: 'Battles'),
    (icon: Icons.code_rounded, label: 'Practice'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = index == currentIndex;
          final color = isActive ? AppColors.accentCyan : AppColors.textHint;
          return InkWell(
            onTap: () => onTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accentCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
