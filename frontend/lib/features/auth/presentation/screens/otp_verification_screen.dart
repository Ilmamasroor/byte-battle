import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isLoading = false;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      AppConstants.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(AppConstants.otpLength, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        return true;
      }
      return false;
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length != AppConstants.otpLength) return;
    setState(() => _isLoading = true);

    // NOTE: there is no OTP/email-verification endpoint in the current
    // backend API — POST /api/auth/register already returns a valid token
    // and logs the user in directly (see RegisterScreen, which now skips
    // this screen entirely). Left as UI-only/simulated so it doesn't
    // pretend to call a real endpoint. Wire this up once/if the backend
    // adds email verification.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed(RouteNames.login);
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    setState(() => _secondsLeft = 60);
    _startTimer();
    // NOTE: same as above — no resend-OTP endpoint on the backend yet.
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingXl),
                const Text('Verify your Email', style: AppTextStyles.heading1),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  widget.email.isEmpty
                      ? 'Enter the 6-digit code we sent you'
                      : 'Enter the 6-digit code sent to ${widget.email}',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    AppConstants.otpLength,
                    (index) => _OtpBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            index < AppConstants.otpLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_otpCode.length == AppConstants.otpLength) {
                          FocusScope.of(context).unfocus();
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                AppButton(
                  label: 'VERIFY',
                  isLoading: _isLoading,
                  onPressed:
                      _otpCode.length == AppConstants.otpLength ? _verify : null,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Center(
                  child: TextButton(
                    onPressed: _secondsLeft == 0 ? _resend : null,
                    child: Text(
                      _secondsLeft > 0
                          ? "Resend code in ${_secondsLeft}s"
                          : 'Resend Code',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.otpBoxSize,
      height: AppDimensions.otpBoxSize + 8,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.heading2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(counterText: ''),
        onChanged: onChanged,
      ),
    );
  }
}
