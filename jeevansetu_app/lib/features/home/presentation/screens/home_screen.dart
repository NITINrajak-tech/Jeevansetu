import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/sos_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../monitoring/providers/sensor_monitor_provider.dart';
import '../widgets/monitoring_status_card.dart';
import '../widgets/location_preview_card.dart';
import '../widgets/recent_activity_card.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sensorMonitorProvider.notifier).startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = authState.user?.name ?? 'Driver';

    // ── Crash Detection Listener ───────────────────────────────────────────
    ref.listen<SensorMonitorState>(sensorMonitorProvider, (previous, next) {
      if (next.crashDetected && !(previous?.crashDetected ?? false)) {
        // Acknowledge to prevent re-triggering.
        ref.read(sensorMonitorProvider.notifier).acknowledgeCrash();
        // Navigate to accident alert (auto SOS flow).
        if (mounted) {
          context.pushNamed(AppRoutes.accidentAlert);
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: authState.user?.avatarUrl != null &&
                              authState.user!.avatarUrl.isNotEmpty
                          ? NetworkImage(authState.user!.avatarUrl)
                          : null,
                      child: authState.user?.avatarUrl == null ||
                              authState.user!.avatarUrl.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Welcome Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            userName,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: isDark ? Colors.white : AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Theme Switcher Button
                    IconButton(
                      icon: Icon(
                        themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.white : AppColors.primaryLight,
                      ),
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).state =
                            themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                      },
                    ),
                  ],
                ),
              ),

              // Dashboard content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Active Monitoring Status Card
                      const MonitoringStatusCard()
                          .animate()
                          .fade(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 16),

                      // Location Preview Card
                      LocationPreviewCard(address: homeState.currentAddress)
                          .animate()
                          .fade(delay: 100.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Big Central SOS Pulse Button
                      Text(
                        'PRESS IN EMERGENCY',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SOSButton(
                        onPressed: () {
                          // Navigate to Accident Alert screen directly
                          context.pushNamed(AppRoutes.accidentAlert);
                        },
                      ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 32),

                      // Recent activity logs
                      RecentActivityCard(activities: homeState.activities)
                          .animate()
                          .fade(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
