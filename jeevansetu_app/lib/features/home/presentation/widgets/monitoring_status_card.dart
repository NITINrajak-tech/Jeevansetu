import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/router/app_router.dart';
import '../../../monitoring/providers/sensor_monitor_provider.dart';
import '../../providers/home_provider.dart';

class MonitoringStatusCard extends ConsumerWidget {
  const MonitoringStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final sensorState = ref.watch(sensorMonitorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detection System',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: isDark ? Colors.white : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensorState.isMonitoring ? 'Scanning live sensors...' : 'System offline',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: sensorState.isMonitoring ? 'Active' : 'Paused',
                type: sensorState.isMonitoring ? StatusType.success : StatusType.warning,
                animate: sensorState.isMonitoring,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sensorState.accelerometer != null || sensorState.gyroscope != null) ...[
            Text(
              'Accelerometer: ${sensorState.accelerometer?.x.toStringAsFixed(1) ?? '--'} / ${sensorState.accelerometer?.y.toStringAsFixed(1) ?? '--'} / ${sensorState.accelerometer?.z.toStringAsFixed(1) ?? '--'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gyroscope: ${sensorState.gyroscope?.x.toStringAsFixed(1) ?? '--'} / ${sensorState.gyroscope?.y.toStringAsFixed(1) ?? '--'} / ${sensorState.gyroscope?.z.toStringAsFixed(1) ?? '--'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GPS: ${sensorState.latitude?.toStringAsFixed(5) ?? '--'}, ${sensorState.longitude?.toStringAsFixed(5) ?? '--'}  Speed: ${sensorState.speedMps?.toStringAsFixed(1) ?? '--'} m/s',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              // Toggle Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => homeNotifier.toggleMonitoring(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: homeState.isMonitoring
                        ? AppColors.warningAmber.withOpacity(0.15)
                        : AppColors.safeGreen.withOpacity(0.15),
                    foregroundColor: homeState.isMonitoring
                        ? AppColors.warningAmber
                        : AppColors.safeGreen,
                    side: BorderSide(
                      color: homeState.isMonitoring
                          ? AppColors.warningAmber.withOpacity(0.4)
                          : AppColors.safeGreen.withOpacity(0.4),
                    ),
                  ),
                  icon: Icon(
                    homeState.isMonitoring ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    homeState.isMonitoring ? 'Pause System' : 'Resume System',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Simulator Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate directly to accident alert screen to demo the flow
                    context.pushNamed(AppRoutes.accidentAlert);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sosRed.withOpacity(0.1),
                    foregroundColor: AppColors.sosRed,
                    side: BorderSide(color: AppColors.sosRed.withOpacity(0.3)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 20),
                  label: const Text('Demo Crash'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
