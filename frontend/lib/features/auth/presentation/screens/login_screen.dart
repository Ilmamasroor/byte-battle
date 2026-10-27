import 'package:flutter/material.dart';
import '../../../onboarding/data/onboarding_gate.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../state/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success = false;
    try {
      // Same 10s ceiling + catch-all as registration (see
      // register_screen.dart) so a hung/500-erroring backend can never
      // leave this screen stuck or crash it. Unlike registration, a
      // failed login is left as a failed login (wrong password, etc.) —
      // it would be actively misleading to drop someone on the dashboard
      // as if they were logged in.
      success = await AuthController.instance
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final next = await OnboardingGate.nextRoute();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(next);
    } else {
      _showError(AuthController.instance.errorMessage ?? 'Login failed. Please try again.');
    }
  }

  void _showError(String message) {
    AppSnackBar.error(context, message);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const AppLogo(logoSize: 24, fontSize: 19),
                    BitMascot(size: 56, mood: BitMood.happy),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.display.copyWith(fontSize: 36),
                    children: const [
                      TextSpan(text: 'Welcome back,\n'),
                      TextSpan(text: 'ready to battle?', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm + 4),
                Text(
                  'Pick up right where you left off. Your streak and Byte DNA are waiting.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email address',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimum 6 characters'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              side: const BorderSide(color: AppColors.border, width: 1.4),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: AppTextStyles.body),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed(RouteNames.forgotPassword),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                AppButton(
                  label: 'LOG IN',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTextStyles.body),
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed(RouteNames.register),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
