import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'stage_common.dart';

/// Checklist/framework stage for interview prep: cards that move from todo to active to done as the steps advance.
class FlowStage extends StatelessWidget {
  final Map<String, dynamic> s;
  const FlowStage({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final raw in asList(s['cards']))
        () {
          final c = asMap(raw);
          final st = str(c['s']);
          final active = st == 'active';
          final done = st == 'done';
          final color = done ? AppColors.success : (active ? AppColors.primary : AppColors.textHint);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: active ? AppColors.primary : (done ? AppColors.success.withOpacity(0.5) : AppColors.border), width: active ? 1.8 : 1),
              boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, spreadRadius: -6)] : null,
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: done || active ? color : AppColors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
                child: Icon(done ? Icons.check_rounded : iconFor(str(c['icon'])), size: 20, color: done || active ? AppColors.onAccent : AppColors.textHint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(str(c['title']), style: AppTextStyles.bodyBold.copyWith(color: st == 'todo' ? AppColors.textSecondary : AppColors.textPrimary)),
                  if (str(c['text']).isNotEmpty) ...[const SizedBox(height: 3), Text(str(c['text']), style: AppTextStyles.body.copyWith(fontSize: 12.5, height: 1.4))],
                ]),
              ),
            ]),
          );
        }(),
    ]);
  }
}
