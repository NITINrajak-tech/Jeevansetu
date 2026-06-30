import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signup(
            _nameController.text.trim(),
            _phoneController.text.trim(),
          );
      if (!mounted) return;
      final errMsg = ref.read(authProvider).errorMessage;
      if (errMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: AppColors.sosRed),
        );
        return;
      }
      context.goNamed(AppRoutes.permissions);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.primaryGradient : null,
          color: isDark ? null : AppColors.surfaceLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join JeevanSetu',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: isDark ? Colors.white : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Setup emergency monitoring and response network',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Details',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your full name'
                              : null,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                            hintText: 'Full Name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          validator: (value) => value == null || value.length < 10
                              ? 'Please enter a valid phone number'
                              : null,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                            hintText: 'Phone Number',
                            prefixText: '+91 ',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Primary Emergency Contact',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactNameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter contact name'
                              : null,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.emergency_outlined, color: AppColors.sosRed),
                            hintText: 'Contact Name (e.g. Mother)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          validator: (value) => value == null || value.length < 10
                              ? 'Please enter valid contact phone'
                              : null,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_rounded, color: AppColors.sosRed),
                            hintText: 'Contact Phone Number',
                            prefixText: '+91 ',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleRegister,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Register & Continue'),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
