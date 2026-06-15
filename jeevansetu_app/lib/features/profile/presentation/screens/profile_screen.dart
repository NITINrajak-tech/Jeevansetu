import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../home/providers/home_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // User info section
                _buildUserInfoCard(context, authState),

                const SizedBox(height: 24),

                // System toggles
                GradientCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Preferences',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: isDark ? Colors.white : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Monitoring switch row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Crash Detection',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'High-frequency accelerometer tracking',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: homeState.isMonitoring,
                            onChanged: (_) => ref.read(homeProvider.notifier).toggleMonitoring(),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      // Countdown selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SOS Countdown Duration',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          DropdownButton<int>(
                            value: 15,
                            dropdownColor: isDark ? AppColors.surfaceDarkCard : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            onChanged: (_) {},
                            items: const [
                              DropdownMenuItem(value: 10, child: Text('10 Seconds')),
                              DropdownMenuItem(value: 15, child: Text('15 Seconds')),
                              DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Localization preferences
                GradientCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localization Settings',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: isDark ? Colors.white : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Language Preference',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          DropdownButton<String>(
                            value: authState.user?.preferredLanguage ?? 'English',
                            dropdownColor: isDark ? AppColors.surfaceDarkCard : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            onChanged: (_) {},
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Hindi', child: Text('Hindi (हिन्दी)')),
                              DropdownMenuItem(value: 'Marathi', child: Text('Marathi (मराठी)')),
                              DropdownMenuItem(value: 'Tamil', child: Text('Tamil (தமிழ்)')),
                              DropdownMenuItem(value: 'Bengali', child: Text('Bengali (বাংলা)')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.goNamed(AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sosRed.withOpacity(0.12),
                      foregroundColor: AppColors.sosRed,
                      side: const BorderSide(color: AppColors.sosRed, width: 1),
                    ),
                    child: const Text('Logout Account'),
                  ),
                ),

                const SizedBox(height: 12),

                // App version info
                Text(
                  'JeevanSetu v1.0.0 • Hackathon Prototype',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, AuthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = state.user;

    return GradientCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user?.avatarUrl == null || user!.avatarUrl.isEmpty
                ? const Icon(Icons.person_rounded, size: 30, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User Profile',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? 'Emergency Identity Verified',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
