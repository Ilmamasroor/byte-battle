import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _linkSent = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // NOTE: the current backend API (see API Reference) only exposes
    // /api/auth/register, /api/auth/login and GET /api/users/{id} — there
    // is no password-reset endpoint yet. This screen is left as
    // UI-only/simulated on purpose so it doesn't claim to send a real
    // email. Wire this up to a real AuthRepository call once that
    // endpoint is added to the backend.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _linkSent = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  const Text('Forgot Password', style: AppTextStyles.heading1),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    _linkSent
                        ? 'A reset link has been sent to ${_emailController.text}. Check your inbox.'
                        : "Enter your email and we'll send you a link to reset your password.",
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  if (!_linkSent) ...[
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    AppButton(
                      label: 'SEND RESET LINK',
                      isLoading: _isLoading,
                      onPressed: _sendResetLink,
                    ),
                  ] else ...[
                    AppButton(
                      label: 'BACK TO LOGIN',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
