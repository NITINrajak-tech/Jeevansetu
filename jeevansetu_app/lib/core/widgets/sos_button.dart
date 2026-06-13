import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Large animated SOS emergency button with pulsing ring effect
class SOSButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const SOSButton({
    super.key,
    required this.onPressed,
    this.size = 140,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: widget.size + 30,
            height: widget.size + 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.sosRed.withOpacity(0.3),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.9, end: 1.1, duration: 1500.ms)
              .fadeOut(duration: 1500.ms),
          // Second pulse ring
          Container(
            width: widget.size + 15,
            height: widget.size + 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.sosRed.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.95, end: 1.15, duration: 1800.ms)
              .fadeOut(duration: 1800.ms),
          // Main button
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.sosGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosRed.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.sosRed.withOpacity(0.3),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SOS',
                    style: AppTextStyles.heroTitle.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
