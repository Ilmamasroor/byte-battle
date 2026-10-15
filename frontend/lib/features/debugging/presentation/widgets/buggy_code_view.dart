import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Read-only, line-numbered code block used on the Debug screen to show
/// the buggy submission — matches the dark monospace "Code" panel in
/// the reference screenshot. Reuses the same dark editor background as
/// `CodeEditor` so both feel like the same surface.
class BuggyCodeView extends StatelessWidget {
  final String code;
  final int? highlightLine;

  const BuggyCodeView({super.key, required this.code, this.highlightLine});

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, size: 16, color: AppColors.accentCyan),
                const SizedBox(width: 6),
                Text('Code', style: AppTextStyles.bodyBold),
                const Spacer(),
                Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines.length, (i) {
                final lineNo = i + 1;
                final isBug = lineNo == highlightLine;
                return Container(
                  width: double.infinity,
                  color: isBug ? AppColors.error.withOpacity(0.12) : null,
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$lineNo',
                          style: AppTextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                            color: isBug ? AppColors.error : AppColors.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          lines[i],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                            color: isBug ? AppColors.error : const Color(0xFFD4D4F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
