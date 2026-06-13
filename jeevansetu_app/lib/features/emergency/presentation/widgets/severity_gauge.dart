import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SeverityGauge extends StatelessWidget {
  final int score;

  const SeverityGauge({
    super.key,
    required this.score,
  });

  Color _getColor(int score) {
    if (score >= 70) return AppColors.criticalRed;
    if (score >= 40) return AppColors.warningAmber;
    return AppColors.safeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final percent = score / 100.0;
    final color = _getColor(score);
    final label = AppColors.severityLabel(score);

    return CircularPercentIndicator(
      radius: 90.0,
      lineWidth: 16.0,
      percent: percent,
      animation: true,
      animationDuration: 1500,
      animateFromLastPercent: true,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: color.withOpacity(0.15),
      progressColor: color,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: AppTextStyles.scoreDisplay.copyWith(
              color: color,
              fontSize: 54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RISK SCORE',
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
