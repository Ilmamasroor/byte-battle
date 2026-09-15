import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';

class CodeEditor extends StatelessWidget {
  final TextEditingController controller;

  const CodeEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: 14,
        minLines: 10,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFFD4D4F5),
          height: 1.5,
        ),
        cursorColor: AppColors.primary,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
