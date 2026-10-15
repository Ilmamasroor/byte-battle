import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';

/// Dashboard top section: logo / notification bell / avatar row, followed
/// by the "Good morning, {name}!" greeting with the italic daily quote,
/// matching the reference dashboard screenshot.
class UserHeader extends StatelessWidget {
  final String name;
  final String avatarInitials;
  final int level;
  final int xp;
  final bool hasNotification;
  final String quote;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const UserHeader({
    super.key,
    required this.name,
    required this.avatarInitials,
    required this.level,
    required this.xp,
    this.hasNotification = true,
    this.quote = 'Better code today,\nstronger future tomorrow.',
    this.onNotificationTap,
    this.onProfileTap,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppLogo(logoSize: 30, fontSize: 18),
            Row(
              children: [
                _NotificationBell(
                  hasNotification: hasNotification,
                  onTap: onNotificationTap,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accentCyan, AppColors.primary],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarInitials,
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.bodyBold),
                          Text(
                            'Level $level • $xp XP',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const Icon(Icons.expand_more_rounded,
                          color: AppColors.textHint, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.heading1.copyWith(fontSize: 24),
                      children: [
                        TextSpan(text: '${_greeting()},\n'),
                        TextSpan(
                          text: '$name!',
                          style: const TextStyle(color: AppColors.accentCyan),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Small steps. Big progress.\nKeep coding! 🚀',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                quote,
                textAlign: TextAlign.right,
                style: AppTextStyles.body.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback? onTap;

  const _NotificationBell({required this.hasNotification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary, size: 24),
            if (hasNotification)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.btnGamificationPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
