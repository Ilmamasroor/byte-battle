import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Cell/node/edge state -> colour. One vocabulary for every stage so a scene reads the same everywhere:
/// cur = the thing being worked on, compare = being examined, swap = changing, done = settled, found = the answer.
Color stateColor(String? s) {
  switch (s) {
    case 'cur':
      return AppColors.primary;
    case 'compare':
      return AppColors.accentCyan;
    case 'swap':
      return AppColors.orchid;
    case 'done':
      return AppColors.success;
    case 'found':
      return AppColors.xp;
    case 'bad':
      return AppColors.error;
    default:
      return AppColors.borderLight;
  }
}

bool stateIsActive(String? s) => s != null && s != 'idle' && s != 'dim' && s != '';

Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> asList(dynamic v) => v is List ? v : const [];
String str(dynamic v) => v?.toString() ?? '';

/// Source listing with the executing line lit, so what you read in code and what you see happen stay linked.
class CodePanel extends StatelessWidget {
  final Map<String, dynamic> code;
  const CodePanel({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final lines = asList(code['lines']).map(str).toList();
    final at = <int>{
      if (code['at'] is num) (code['at'] as num).toInt(),
      for (final a in asList(code['at']))
        if (a is num) a.toInt(),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              color: at.contains(i) ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: AppTextStyles.code.copyWith(fontSize: 11, color: at.contains(i) ? AppColors.primary : AppColors.textHint))),
                  Expanded(
                    child: Text(lines[i],
                        style: AppTextStyles.code.copyWith(
                            fontSize: 12, color: at.contains(i) ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: at.contains(i) ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  if (at.contains(i)) const Icon(Icons.arrow_left_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A titled card that glows when its component is highlighted in the current step.
class StageCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool lit;
  final Widget child;
  const StageCard({super.key, required this.title, required this.icon, required this.color, required this.lit, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lit ? color.withOpacity(0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lit ? color : AppColors.border, width: lit ? 1.8 : 1),
        boxShadow: lit ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 22, spreadRadius: -6)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: lit ? color : AppColors.textHint),
            const SizedBox(width: 6),
            Text(title.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(fontSize: 10, color: lit ? color : AppColors.textHint)),
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Small animated "data moving" connector between two stacked cards.
class BusConnector extends StatelessWidget {
  final bool active;
  final bool down;
  final Color color;
  const BusConnector({super.key, required this.active, this.down = true, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Center(
        child: active
            ? TweenAnimationBuilder<double>(
                key: ValueKey('bus_$down'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                builder: (context, t, _) => Stack(alignment: Alignment.center, children: [
                  Container(width: 2, height: 26, color: color.withOpacity(0.5)),
                  Positioned(top: (down ? t : 1 - t) * 18, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
                ]),
              )
            : Container(width: 2, height: 26, color: AppColors.border),
      ),
    );
  }
}

IconData iconFor(String? name) {
  switch (name) {
    case 'search':
      return Icons.search_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'check':
      return Icons.check_circle_rounded;
    case 'timer':
      return Icons.timer_rounded;
    case 'chat':
      return Icons.forum_rounded;
    case 'people':
      return Icons.groups_rounded;
    case 'storage':
      return Icons.storage_rounded;
    case 'speed':
      return Icons.speed_rounded;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'flag':
      return Icons.flag_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'loop':
      return Icons.loop_rounded;
    case 'lock':
      return Icons.lock_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'build':
      return Icons.build_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'list':
      return Icons.checklist_rounded;
    case 'compare':
      return Icons.compare_arrows_rounded;
    case 'help':
      return Icons.help_rounded;
    case 'cloud':
      return Icons.cloud_rounded;
    case 'lightbulb':
    default:
      return Icons.lightbulb_rounded;
  }
}
