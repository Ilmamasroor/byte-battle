import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// A single numbered, expandable hint row shown on [BattleFeedback]
/// ("Hint 1", "Hint 2", ...). Collapsed by default; tapping reveals the
/// full hint text. Matches the glassy surface + glowing border used
/// everywhere else in the app (see `GlowCard`).
class HintButton extends StatefulWidget {
  final int number;
  final String text;
  final bool initiallyExpanded;

  const HintButton({
    super.key,
    required this.number,
    required this.text,
    this.initiallyExpanded = false,
  });

  @override
  State<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<HintButton> {
  late bool _expanded = widget.initiallyExpanded;
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    // Hardcoded 2-second "thinking" delay before the hint text appears.
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _expanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.borderLight.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentCyan),
              ),
              child: Text(
                '${widget.number}',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.accentCyan),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hint ${widget.number}', style: AppTextStyles.bodyBold),
                  if (_loading) ...[
                    const SizedBox(height: 4),
                    Text('Thinking...', style: AppTextStyles.caption),
                  ] else if (_expanded) ...[
                    const SizedBox(height: 4),
                    Text(widget.text, style: AppTextStyles.body),
                  ],
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}
