import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Multiline answer box used on the Technical Interview screen, with a
/// "Type your explanation here..." hint and a live character counter.
class AnswerInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final String hintText;

  const AnswerInput({
    super.key,
    required this.controller,
    this.maxLength = 500,
    this.hintText = 'Type your explanation here...',
  });

  @override
  State<AnswerInput> createState() => _AnswerInputState();
}

class _AnswerInputState extends State<AnswerInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: TextField(
              controller: widget.controller,
              maxLength: widget.maxLength,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.hint,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${widget.controller.text.length}/${widget.maxLength}',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
