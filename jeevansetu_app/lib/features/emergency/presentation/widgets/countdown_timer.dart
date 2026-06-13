import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CountdownTimer extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const CountdownTimer({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final percent = secondsRemaining / totalSeconds;

    return CircularPercentIndicator(
      radius: 90.0,
      lineWidth: 12.0,
      percent: percent,
      animation: true,
      animateFromLastPercent: true,
      animationDuration: 1000,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: AppColors.sosRed.withOpacity(0.15),
      progressColor: AppColors.sosRed,
      center: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$secondsRemaining',
              style: AppTextStyles.countdown.copyWith(
                color: Colors.white,
                fontSize: 64,
              ),
            ),
            Text(
              'SECONDS',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
