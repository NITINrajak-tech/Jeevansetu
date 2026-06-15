import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/countdown_timer.dart';
import '../../providers/emergency_provider.dart';

class AccidentAlertScreen extends ConsumerStatefulWidget {
  const AccidentAlertScreen({super.key});

  @override
  ConsumerState<AccidentAlertScreen> createState() => _AccidentAlertScreenState();
}

class _AccidentAlertScreenState extends ConsumerState<AccidentAlertScreen> {
  @override
  void initState() {
    super.initState();
    // Start countdown immediately on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyProvider.notifier).startCountdown();
    });
  }

  void _onSafePressed() {
    ref.read(emergencyProvider.notifier).cancelAccident();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency alert cancelled. Glad you are safe!'),
        backgroundColor: AppColors.safeGreen,
      ),
    );
    context.goNamed(AppRoutes.home);
  }

  void _onSosPressed() {
    ref.read(emergencyProvider.notifier).confirmAccident();
    context.goNamed(AppRoutes.severityResult);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyProvider);

    // Auto navigate if confirmed
    if (state.status == AccidentStatus.confirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && GoRouterState.of(context).name == AppRoutes.accidentAlert) {
          context.goNamed(AppRoutes.severityResult);
        }
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.alertGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Warning Pulsing Shield
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms, curve: Curves.easeInOut)
                    .then()
                    .shake(hz: 3, duration: 400.ms),

                const SizedBox(height: 24),

                Text(
                  'CRASH DETECTED',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    letterSpacing: 1,
                  ),
                ).animate().fade().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'An impact event was registered by your sensors.\nSOS protocol will activate automatically.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ).animate().fade(delay: 200.ms),

                const Spacer(),

                // Animated Circular Countdown
                CountdownTimer(
                  secondsRemaining: state.countdownSeconds,
                  totalSeconds: 15,
                ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

                const Spacer(),

                // Buttons UI
                Column(
                  children: [
                    // I am Safe button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onSafePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.safeGreenDark,
                          elevation: 8,
                          shadowColor: Colors.black45,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 24),
                        label: Text(
                          'I AM SAFE (DISMISS)',
                          style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                        ),
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // Trigger SOS immediately
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _onSosPressed,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'SEND SOS NOW',
                          style: AppTextStyles.buttonText.copyWith(
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
