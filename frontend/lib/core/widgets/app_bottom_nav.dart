import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Shared bottom navigation (Home / Learn / Battles / Practice / Profile). The active tab gets a Flame pill
/// behind its icon; inactive tabs stay quiet.
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
    (icon: Icons.auto_stories_rounded, label: 'Learn'),
    (icon: Icons.bolt_rounded, label: 'Battles'),
    (icon: Icons.terminal_rounded, label: 'Practice'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.96),
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: item.label,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 52 : 36,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: isActive ? AppColors.onAccent : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isActive ? AppColors.textPrimary : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
