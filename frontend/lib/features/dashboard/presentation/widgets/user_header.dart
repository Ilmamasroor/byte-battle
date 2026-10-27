import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/personalization/hero_prefs.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/personalize_sheet.dart';

/// Dashboard top section: brand + avatar row, a greeting that knows the time of day and the learner's level
/// title, and the companion ("Bit" unless renamed) reacting to the learner's streak. Tapping the avatar opens
/// the personalisation sheet.
class UserHeader extends StatelessWidget {
  final String name;
  final String avatarInitials;
  final int level;
  final int xp;
  final int streakDays;
  final bool hasNotification;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const UserHeader({
    super.key,
    required this.name,
    required this.avatarInitials,
    required this.level,
    required this.xp,
    this.streakDays = 0,
    this.hasNotification = false,
    this.onNotificationTap,
    this.onProfileTap,
  });

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 5 || hour >= 22) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// The companion's mood and one line of encouragement that fits the moment.
  static (BitMood, String) companionLine(int streakDays, DateTime now) {
    final night = now.hour >= 22 || now.hour < 5;
    if (night) return (BitMood.sleepy, 'Late-night coding? One concept, then rest. Sleep locks memory in.');
    if (streakDays >= 7) return (BitMood.cheer, '$streakDays days in a row. You are on fire, keep the chain alive!');
    if (streakDays >= 2) return (BitMood.cheer, '$streakDays-day streak! One more step today keeps it going.');
    if (streakDays == 1) return (BitMood.happy, 'Day one done. Come back tomorrow and make it two.');
    return (BitMood.curious, 'Ready when you are. One small win today starts a streak.');
  }

  static const _weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (mood, line) = companionLine(streakDays, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppLogo(logoSize: 22, fontSize: 18),
            Row(
              children: [
                _NotificationBell(hasNotification: hasNotification, onTap: onNotificationTap),
                const SizedBox(width: AppDimensions.spacingSm),
                Semantics(
                  button: true,
                  label: 'Personalise your avatar',
                  child: GestureDetector(
                    onTap: () => showPersonalizeSheet(context, initials: avatarInitials),
                    onLongPress: onProfileTap,
                    child: HeroAvatar(initials: avatarInitials, size: 42),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        ListenableBuilder(
          listenable: HeroPrefs.instance,
          builder: (context, _) => Text(
            '${_weekdays[now.weekday - 1]}  ·  LEVEL $level  ·  ${HeroPrefs.titleForLevel(level).toUpperCase()}',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryLight),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTextStyles.display.copyWith(fontSize: 34),
            children: [
              TextSpan(text: '${greeting(now)},\n'),
              TextSpan(text: name, style: const TextStyle(color: AppColors.primary)),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BitMascot(size: 56, mood: mood),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListenableBuilder(
                  listenable: HeroPrefs.instance,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(HeroPrefs.instance.companionName.toUpperCase(),
                          style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentCyan, fontSize: 10)),
                      const SizedBox(height: 3),
                      Text(line, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                    ],
                  ),
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
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 24),
            if (hasNotification)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
