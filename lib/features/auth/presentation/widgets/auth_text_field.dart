import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Thin wrapper around [AppTextField] kept as a separate widget
/// so auth screens can evolve independently (e.g. add strength
/// meters, OTP-aware fields, etc.) without touching the shared core widget.
class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: icon,
      isPassword: isPassword,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
