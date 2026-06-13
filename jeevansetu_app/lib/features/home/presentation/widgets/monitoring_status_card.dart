import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/home_provider.dart';

class MonitoringStatusCard extends ConsumerWidget {
  const MonitoringStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
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
                    homeState.isMonitoring ? 'Scanning sensors...' : 'System offline',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: homeState.isMonitoring ? 'Active' : 'Paused',
                type: homeState.isMonitoring ? StatusType.success : StatusType.warning,
                animate: homeState.isMonitoring,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
