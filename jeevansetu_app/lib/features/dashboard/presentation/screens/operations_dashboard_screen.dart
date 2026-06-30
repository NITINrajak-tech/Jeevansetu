import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/operations_dashboard_provider.dart';
import '../../../tracking/providers/tracking_provider.dart';
import '../widgets/operations_live_map.dart';

class OperationsDashboardScreen extends ConsumerStatefulWidget {
  const OperationsDashboardScreen({super.key});

  @override
  ConsumerState<OperationsDashboardScreen> createState() =>
      _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState
    extends ConsumerState<OperationsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startSimulatingTracking();
      ref.read(operationsDashboardProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final opsState = ref.watch(operationsDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operations = opsState.payload?['operations'] as Map<String, dynamic>?;
    final incidents = (operations?['active_incidents'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final liveMarkers = (operations?['live_map']?['incident_markers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final firstIncident = incidents.isNotEmpty ? incidents.first : null;
    final victimLat = (firstIncident?['latitude'] as num?)?.toDouble() ?? AppConstants.mockLatitude;
    final victimLng = (firstIncident?['longitude'] as num?)?.toDouble() ?? AppConstants.mockLongitude;
    final severity = firstIncident?['severity']?.toString() ?? 'Critical';

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(operationsDashboardProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations',
                          style: AppTextStyles.screenTitle.copyWith(
                            color: isDark ? Colors.white : AppColors.primaryLight,
                          ),
                        ),
                        Text(
                          'Notification, volunteer, and incident control',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open dispatch tracking',
                    onPressed: () => context.pushNamed(AppRoutes.liveTracking),
                    icon: const Icon(Icons.near_me_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.ambulanceDashboard),
                  icon: const Icon(Icons.local_taxi_rounded),
                  label: const Text('Open Ambulance Dispatch'),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 360,
                width: double.infinity,
                child: OperationsLiveMap(
                  victimLat: victimLat,
                  victimLng: victimLng,
                  responderLat: state.ambulanceLat,
                  responderLng: state.ambulanceLng,
                  severity: severity,
                ),
              ).animate().fade(duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.notification_important_rounded,
                      label: 'Alerts',
                      value: '${operations?['notification_channels']?.length ?? 0} groups',
                      color: AppColors.sosRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Volunteers',
                      value: '${firstIncident?['nearby_volunteers'] ?? 0} nearby',
                      color: AppColors.warningAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.local_hospital_rounded,
                      label: 'Hospital',
                      value: firstIncident?['recommended_hospital']?.toString() ?? state.hospitalName,
                      color: AppColors.safeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.timer_rounded,
                      label: 'ETA',
                      value: firstIncident?['eta']?.toString() ?? '${state.etaMinutes} min',
                      color: AppColors.infoBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _OperationsPanel(
                status: _statusText(state.status),
                distanceKm: state.distanceKm,
                incidents: incidents,
                operations: operations,
                errorMessage: opsState.errorMessage,
                lastUpdated: opsState.lastUpdated,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _statusText(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.dispatching:
        return 'Dispatching responders';
      case TrackingStatus.enRoute:
        return 'Responder en route';
      case TrackingStatus.arrived:
        return 'Responder arrived';
    }
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  final String status;
  final double distanceKm;
  final List<Map<String, dynamic>> incidents;
  final Map<String, dynamic>? operations;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const _OperationsPanel({
    required this.status,
    required this.distanceKm,
    required this.incidents,
    required this.operations,
    required this.errorMessage,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Incident INC001',
            style: AppTextStyles.sectionTitle.copyWith(
              color: isDark ? Colors.white : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            icon: Icons.warning_amber_rounded,
            label: 'Severity',
            value: incidents.isNotEmpty ? incidents.first['severity']?.toString() ?? 'Critical' : 'Critical',
            color: AppColors.criticalRed,
          ),
          _StatusRow(
            icon: Icons.notifications_active_rounded,
            label: 'FCM',
            value: operations?['realtime']?['push_alerts']?.toString() ?? 'Family, Friends, Volunteers notified',
            color: AppColors.primary,
          ),
          _StatusRow(
            icon: Icons.radar_rounded,
            label: 'Volunteer Search',
            value: incidents.isNotEmpty
                ? '1 km -> 3 km -> 5 km, ${incidents.first['volunteer_status'] ?? 'searching'}'
                : '1 km -> 3 km -> 5 km active',
            color: AppColors.warningAmber,
          ),
          _StatusRow(
            icon: Icons.route_rounded,
            label: 'Responder',
            value: '$status, ${distanceKm.toStringAsFixed(1)} km away',
            color: AppColors.infoBlue,
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last updated ${lastUpdated!.toLocal().hour.toString().padLeft(2, '0')}:${lastUpdated!.toLocal().minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.sosRed),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
