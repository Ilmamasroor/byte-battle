import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';
import 'preference_chip.dart';

/// A handful of common goals, shown as quick-pick chips. Anything else
/// can still be typed into the free-text field below — the backend
/// takes `careerGoal` as a free string (upper-cased + underscore-joined
/// by the screen before it's sent).
const List<String> _presetCareerGoals = [
  'Software Engineer',
  'Backend Developer',
  'Frontend Developer',
  'Data Scientist',
  'Mobile Developer',
  'DevOps Engineer',
];

/// Career-goal picker for the ByteDNA Setup form — a row of preset
/// quick-pick chips plus a free-text field, wrapped in the same
/// [GlowCard] look used elsewhere in the app. Fully controlled by the
/// parent: [controller] holds the raw (not-yet-uppercased) text and
/// [onChanged] fires on every edit, whether from a chip tap or typing.
class CareerGoalCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const CareerGoalCard({
    super.key,
    required this.controller,
    this.onChanged,
  });

  void _selectPreset(String preset) {
    controller.text = preset;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onChanged?.call(preset);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.btnAccentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spacingSm,
            runSpacing: AppDimensions.spacingSm,
            children: _presetCareerGoals.map((preset) {
              return PreferenceChip(
                label: preset,
                selected: controller.text.trim().toLowerCase() == preset.toLowerCase(),
                onTap: () => _selectPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text('Or type your own', style: AppTextStyles.caption),
          const SizedBox(height: AppDimensions.spacingSm),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTextStyles.bodyBold,
            decoration: const InputDecoration(
              hintText: 'e.g. Software Engineer',
              prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textHint, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
