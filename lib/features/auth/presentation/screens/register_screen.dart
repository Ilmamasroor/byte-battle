import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../state/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showMessage('Please agree to the Terms and Privacy Policy to continue.');
      return;
    }
    setState(() => _isLoading = true);

    // 5-second wait after tapping SIGN UP, before the API is even hit.
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    bool success = false;
    try {
      // `ApiClient` itself also caps every request at 10s (see
      // api_client.dart), so this timeout is a matching last line of
      // defense: even if something upstream ever hangs longer than that,
      // the SIGN UP button never spins forever and nothing here can
      // crash the screen.
      success = await AuthController.instance
          .register(
            email: _emailController.text,
            password: _passwordController.text,
            // The API takes a single `username` field — this form's "Full
            // Name" input is sent as that username.
            username: _nameController.text,
          )
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Registration succeeded — send the user straight into the
      // mandatory ByteDNA setup form (POST /api/ai/onboarding) instead
      // of the dashboard. `pushNamedAndRemoveUntil` clears the stack, so
      // there's nothing left behind this screen to "pop" back to or
      // skip past — the form must be completed before the dashboard is
      // reachable.
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.byteDnaSetup,
        (route) => false,
      );
    } else {
      // Registration failed — server error (500), timeout, or anything
      // else unexpected. Rather than leaving the person stuck on a
      // broken/crashed-looking form, show a quick message and drop them
      // safely on the dashboard instead of a dead end.
      _showMessage(
        AuthController.instance.errorMessage ?? 'Registration failed. Please try again.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.dashboard,
        (route) => false,
      );
    }
  }

  void _showMessage(String message) {
    AppSnackBar.error(context, message);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const AppLogo(logoSize: 26, fontSize: 16),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                RichText(
                  text: const TextSpan(
                    style: AppTextStyles.heading1,
                    children: [
                      TextSpan(text: 'Create '),
                      TextSpan(text: 'Account', style: TextStyle(color: AppColors.accentCyan)),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Start your Byte Battle journey today',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                AuthTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
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
                  hint: 'Create a password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Minimum 8 characters'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                _PasswordRequirements(password: _password),
                const SizedBox(height: AppDimensions.spacingMd),
                AuthTextField(
                  controller: _confirmController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => (v != _passwordController.text)
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        side: const BorderSide(color: AppColors.border, width: 1.4),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          children: [
                            Text('I agree to the ', style: AppTextStyles.body),
                            const Text(
                              'Terms',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: AppColors.accentCyan,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            Text(' and ', style: AppTextStyles.body),
                            const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: AppColors.accentCyan,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                AppButton(
                  label: 'SIGN UP',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.body),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentCyan,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
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

/// Small pill checklist under the password field ("1 uppercase",
/// "1 lowercase", "1 number", "1 special character") — each chip lights
/// up cyan with a check icon as soon as the typed password satisfies it,
/// matching the reference register screen's requirement row.
class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = <String, bool>{
      '1 uppercase': password.contains(RegExp(r'[A-Z]')),
      '1 lowercase': password.contains(RegExp(r'[a-z]')),
      '1 number': password.contains(RegExp(r'[0-9]')),
      '1 special character': password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]')),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rules.entries.map((entry) {
        final met = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: met
                ? AppColors.accentCyan.withOpacity(0.12)
                : AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(
              color: met ? AppColors.accentCyan : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                met ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 13,
                color: met ? AppColors.accentCyan : AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                entry.key,
                style: AppTextStyles.caption.copyWith(
                  color: met ? AppColors.accentCyan : AppColors.textHint,
                  fontWeight: met ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
