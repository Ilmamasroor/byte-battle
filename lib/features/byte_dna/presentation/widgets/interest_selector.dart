import 'package:flutter/material.dart';
import '../../../../app/theme/app_dimensions.dart';
import 'preference_chip.dart';

/// Multi-select chip list used for the `interests` field on the ByteDNA
/// Setup form. Purely controlled by the parent screen — it just lays
/// out [PreferenceChip]s for [options] and reports taps via [onToggle];
/// the screen owns the actual `Set<String>` of selected interests.
class InterestSelector extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const InterestSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingSm,
      runSpacing: AppDimensions.spacingSm,
      children: options.map((option) {
        return PreferenceChip(
          label: option,
          selected: selected.contains(option),
          onTap: () => onToggle(option),
        );
      }).toList(),
    );
  }
}
