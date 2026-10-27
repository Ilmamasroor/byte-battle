import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'brand/byte_mark.dart';

/// Shared Byte Battle brand lockup: the pixel-B [ByteMark] plus, optionally, the wordmark.
///
/// `logoSize` is the mark's base size (kept from the old API so existing call sites still work); the mark is
/// drawn at 1.4x that. Pass `showWordmark: false` for the icon only.
class AppLogo extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final bool showWordmark;

  const AppLogo({super.key, this.logoSize = 32, this.fontSize = 20, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    final markSize = logoSize * 1.4;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ByteMark(size: markSize),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.28),
          Wordmark(fontSize: fontSize),
        ],
      ],
    );
  }
}

/// "Byte" in light, "Battle" in Flame: one word, two weights of the story (learn, then fight).
class Wordmark extends StatelessWidget {
  final double fontSize;
  const Wordmark({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.logoTitle.copyWith(fontSize: fontSize, height: 1),
        children: const [
          TextSpan(text: 'Byte', style: TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: 'Battle', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}
