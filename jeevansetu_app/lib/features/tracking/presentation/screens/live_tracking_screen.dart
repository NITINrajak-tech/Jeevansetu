import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/tracking_bottom_sheet.dart';
import '../../providers/tracking_provider.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startSimulatingTracking();
    });
  }

  String _getStatusLabel(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.dispatching:
        return 'Dispatching';
      case TrackingStatus.enRoute:
        return 'En Route';
      case TrackingStatus.arrived:
        return 'Arrived';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen map placeholder
          Positioned.fill(
            child: MapPlaceholder(
              victimLatitude: 28.6139,
              victimLongitude: 77.2090,
              hospitalLatitude: 28.6220,
              hospitalLongitude: 77.2100,
              ambulanceLocations: [
                [state.ambulanceLat, state.ambulanceLng],
              ],
            ),
          ),

          // Custom floating header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDarkElevated.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.primaryLight, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trauma Dispatch',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isDark ? Colors.white : AppColors.primaryLight,
                          ),
                        ),
                        Text(
                          'Realtime GPS updates activated',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.sosRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom floating actions (re-route / choose hospital)
          Positioned(
            right: 20,
            bottom: 330,
            child: FloatingActionButton(
              heroTag: 'change_hospital_fab',
              onPressed: () => context.pushNamed(AppRoutes.hospitals),
              backgroundColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.local_hospital_rounded),
            ),
          ),

          // Tracking details bottom sheet pinned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TrackingBottomSheet(
              etaMinutes: state.etaMinutes,
              distanceKm: state.distanceKm,
              hospitalName: state.hospitalName,
              trackingStatusLabel: _getStatusLabel(state.status),
            ),
          ),
        ],
      ),
    );
  }
}
