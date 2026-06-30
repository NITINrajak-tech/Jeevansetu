import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../widgets/otp_input_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpState = false;
  String _enteredOtp = '';
  int _resendTimerSeconds = 30;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() {
          _resendTimerSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleSendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).requestOtp(_phoneController.text);
      setState(() {
        _isOtpState = true;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent! (Demo: use 123456 or 1234)'),
          backgroundColor: AppColors.infoBlue,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final success =
        await ref.read(authProvider.notifier).verifyOtp(_enteredOtp);
    if (!mounted) return;
    if (success) {
      final authState = ref.read(authProvider);
      if (authState.allPermissionsGranted) {
        context.goNamed(AppRoutes.home);
      } else {
        context.goNamed(AppRoutes.permissions);
      }
    } else {
      final errMsg =
          ref.read(authProvider).errorMessage ?? 'Invalid code. Use 123456';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.sosRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.primaryGradient : null,
          color: isDark ? null : AppColors.surfaceLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ).animate().scale(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 20),

                Text(
                  'JeevanSetu',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: isDark ? Colors.white : AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Verify your number to start crash monitoring',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),

                const SizedBox(height: 40),

                // Card container
                GradientCard(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isOtpState
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildPhoneInputView(authState),
                    secondChild: _buildOtpVerificationView(authState),
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 30),

                // Mock account info
                if (!_isOtpState)
                  TextButton(
                    onPressed: () => context.pushNamed(AppRoutes.signup),
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primary,
                        fontSize: 14,
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

  Widget _buildPhoneInputView(AuthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: AppTextStyles.cardTitle.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid 10-digit number';
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
              hintText: 'Enter 10 digit phone number',
              prefixText: '+91 ',
              prefixStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.status == AuthStatus.loading ? null : _handleSendOtp,
              child: state.status == AuthStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Get OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationView(AuthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () {
                setState(() {
                  _isOtpState = false;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Verification Code',
              style: AppTextStyles.cardTitle.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to +91 ${_phoneController.text}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 24),
        OtpInputField(
          length: 6,
          onChanged: (code) {
            setState(() {
              _enteredOtp = code;
            });
          },
          onCompleted: (code) {
            setState(() {
              _enteredOtp = code;
            });
            _handleVerifyOtp();
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _enteredOtp.length < 6 ? null : _handleVerifyOtp,
            child: const Text('Verify & Proceed'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            _resendTimerSeconds > 0
                ? Text(
                    'Resend in ${_resendTimerSeconds}s',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : TextButton(
                    onPressed: _startResendTimer,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend Code',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
