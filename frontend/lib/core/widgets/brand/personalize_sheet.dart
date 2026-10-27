import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../personalization/hero_prefs.dart';
import 'bit_mascot.dart';

/// "Make it yours": a bottom sheet to choose the avatar colours/glyph and rename the companion. Changes apply
/// live (the preview at the top is the real [HeroAvatar]).
Future<void> showPersonalizeSheet(BuildContext context, {required String initials}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg + 4)),
    ),
    builder: (_) => _PersonalizeSheet(initials: initials),
  );
}

class _PersonalizeSheet extends StatefulWidget {
  final String initials;
  const _PersonalizeSheet({required this.initials});

  @override
  State<_PersonalizeSheet> createState() => _PersonalizeSheetState();
}

class _PersonalizeSheetState extends State<_PersonalizeSheet> {
  late final TextEditingController _name = TextEditingController(text: HeroPrefs.instance.companionName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = HeroPrefs.instance;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding, 12, AppDimensions.screenPadding, 24),
          child: ListenableBuilder(
            listenable: prefs,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    HeroAvatar(initials: widget.initials, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Make it yours', style: AppTextStyles.heading2),
                          const SizedBox(height: 2),
                          Text('Saved on this device. Change it any time.', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    BitMascot(size: 52, mood: BitMood.cheer),
                  ],
                ),
                const SizedBox(height: 22),
                Text('AVATAR COLOUR', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < HeroPrefs.palettes.length; i++)
                      _Swatch(
                        colors: HeroPrefs.palettes[i].$2,
                        label: HeroPrefs.palettes[i].$1,
                        selected: prefs.paletteIndex == i,
                        onTap: () => prefs.update(palette: i),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('AVATAR SYMBOL', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < HeroPrefs.glyphs.length; i++)
                      _GlyphChip(
                        icon: HeroPrefs.glyphs[i].$2,
                        label: HeroPrefs.glyphs[i].$1,
                        selected: prefs.glyphIndex == i,
                        onTap: () => prefs.update(glyph: i),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('YOUR COMPANION', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  maxLength: 14,
                  style: AppTextStyles.bodyBold,
                  decoration: const InputDecoration(
                    hintText: 'Name your study buddy',
                    counterText: '',
                    prefixIcon: Icon(Icons.pets_rounded, color: AppColors.accentCyan),
                  ),
                  onChanged: (v) => prefs.update(companion: v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final List<Color> colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({required this.colors, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label colour',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? AppColors.textPrimary : Colors.transparent, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: AppColors.onAccent, size: 20) : null,
          ),
        ),
      ),
    );
  }
}

class _GlyphChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GlyphChip({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.16) : AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
          ),
          child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
