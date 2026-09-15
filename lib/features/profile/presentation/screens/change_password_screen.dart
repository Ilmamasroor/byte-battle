import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/state/auth_controller.dart';

/// `PUT /api/users/me/password` — current password + new password, with
/// a client-side confirm field (the backend itself only needs the two).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await AuthController.instance.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.success(context, 'Password changed successfully.');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(
        context,
        AuthController.instance.errorMessage ?? 'Could not change password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Change Password'),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingLg),
                const Text('Change Password', style: AppTextStyles.heading1),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Enter your current password and choose a new one.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                AppTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                AppTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Create a new password',
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Minimum 8 characters'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  validator: (v) => (v != _newPasswordController.text)
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                AppButton(
                  label: 'UPDATE PASSWORD',
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
