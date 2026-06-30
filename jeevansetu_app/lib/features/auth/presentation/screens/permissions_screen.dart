import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../../monitoring/providers/sensor_monitor_provider.dart';
import '../../../../data/services/device_token_service.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final _deviceTokenService = DeviceTokenService();

  Future<bool> _grantLocationPermission() async {
    final allowed = await ref.read(sensorMonitorProvider.notifier).ensureLocationPermission();
    if (allowed) {
      ref.read(authProvider.notifier).toggleGpsPermission();
    }
    return allowed;
  }

  Future<bool> _grantNotificationPermission() async {
    final granted = await _deviceTokenService.requestNotificationPermission();
    if (granted) {
      ref.read(authProvider.notifier).toggleNotificationsPermission();
      try {
        await _deviceTokenService.syncTokenToBackend();
      } catch (_) {}
    }
    return granted;
  }

  Future<void> _grantAll() async {
    final locationGranted = await _grantLocationPermission();
    if (!ref.read(authProvider).hasSensorsPermission) {
      ref.read(authProvider.notifier).toggleSensorsPermission();
    }
    final sensorsGranted = ref.read(authProvider).hasSensorsPermission;
    final notificationsGranted = await _grantNotificationPermission();
    if (locationGranted && sensorsGranted && notificationsGranted && mounted) {
      context.goNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Required Permissions',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: isDark ? Colors.white : AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JeevanSetu requires the following permissions to run background monitoring and emergency response.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),

                // Permissions List
                Expanded(
                  child: ListView(
                    children: [
                      _buildPermissionCard(
                        context: context,
                        title: 'GPS Location',
                        description: 'Needed to pinpoint and share your live location with responders during emergencies.',
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.infoBlue,
                        isGranted: authState.hasGpsPermission,
                        onChanged: (value) {
                          if (value) {
                            _grantLocationPermission();
                          } else {
                            authNotifier.toggleGpsPermission();
                          }
                        },
                      ).animate().fade(delay: 100.ms).slideX(begin: 0.1, end: 0),

                      const SizedBox(height: 16),

                      _buildPermissionCard(
                        context: context,
                        title: 'Motion Sensors',
                        description: 'Uses your phone\'s accelerometer and gyroscope to automatically detect crashes.',
                        icon: Icons.sensors_rounded,
                        iconColor: AppColors.warningAmber,
                        isGranted: authState.hasSensorsPermission,
                        onChanged: (_) => authNotifier.toggleSensorsPermission(),
                      ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0),

                      const SizedBox(height: 16),

                      _buildPermissionCard(
                        context: context,
                        title: 'Push Notifications',
                        description: 'Used to send critical SOS countdowns, alerts, and tracking statuses.',
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.sosRed,
                        isGranted: authState.hasNotificationsPermission,
                        onChanged: (value) {
                          if (value) {
                            _grantNotificationPermission();
                          } else {
                            authNotifier.toggleNotificationsPermission();
                          }
                        },
                      ).animate().fade(delay: 300.ms).slideX(begin: 0.1, end: 0),
                    ],
                  ),
                ),

                // Grant all or Continue button
                Column(
                  children: [
                    if (!authState.allPermissionsGranted)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _grantAll,
                          child: const Text('Grant All Permissions'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.allPermissionsGranted
                            ? () => context.goNamed(AppRoutes.home)
                            : null,
                        child: const Text('Continue to Dashboard'),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isGranted,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Switch
          Switch(
            value: isGranted,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
