import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../data/models/activity_model.dart';

class RecentActivityCard extends StatelessWidget {
  final List<ActivityModel> activities;

  const RecentActivityCard({
    super.key,
    required this.activities,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'monitoring':
        return Icons.sensors_rounded;
      case 'alert':
        return Icons.notifications_active_rounded;
      case 'sos':
        return Icons.emergency_rounded;
      case 'system':
      default:
        return Icons.settings_suggest_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'monitoring':
        return AppColors.safeGreen;
      case 'alert':
        return AppColors.warningAmber;
      case 'sos':
        return AppColors.sosRed;
      case 'system':
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Log Activity',
                style: AppTextStyles.cardTitle.copyWith(
                  color: isDark ? Colors.white : AppColors.primaryLight,
                ),
              ),
              const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent activities recorded.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(4).length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                height: 24,
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                final iconColor = _getColor(activity.activityType);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Circle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(activity.activityType),
                        color: iconColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                activity.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _formatTime(activity.timestamp),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark.withOpacity(0.8) : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
