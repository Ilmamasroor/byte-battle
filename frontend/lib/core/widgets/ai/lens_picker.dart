import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../personalization/hero_prefs.dart';
import '../../personalization/lens.dart';

/// "Explain it through...": a scrolling row of lens chips. Choosing one is remembered and tells the AI which world
/// to build the analogy or mnemonic from (movies, cricket, gaming...). "Mine" follows the learner's Byte DNA.
class LensPicker extends StatelessWidget {
  final ValueChanged<String?> onChanged;
  const LensPicker({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HeroPrefs.instance,
      builder: (context, _) {
        final current = HeroPrefs.instance.lens;
        Widget chip(String? id, String label, IconData icon, Color color) {
          final sel = current == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (sel) return;
                HeroPrefs.instance.setLens(id);
                onChanged(id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? color : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: sel ? color : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 16, color: sel ? AppColors.onAccent : color),
                  const SizedBox(width: 6),
                  Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: sel ? AppColors.onAccent : AppColors.textSecondary)),
                ]),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXPLAIN IT THROUGH', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                chip(null, 'Mine', Icons.favorite_rounded, AppColors.primaryLight),
                for (final l in Lens.all) chip(l.id, l.label, l.icon, l.color),
              ]),
            ),
          ],
        );
      },
    );
  }
}
