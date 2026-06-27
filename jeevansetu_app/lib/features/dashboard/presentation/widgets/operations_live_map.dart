import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OperationsLiveMap extends StatelessWidget {
  final double victimLat;
  final double victimLng;
  final double responderLat;
  final double responderLng;
  final String severity;

  const OperationsLiveMap({
    super.key,
    required this.victimLat,
    required this.victimLng,
    required this.responderLat,
    required this.responderLng,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OperationsMapPainter(
                isDark: isDark,
                responderProgress: _progressFromCoordinates(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _MapBadge(
              icon: Icons.warning_rounded,
              label: severity,
              color: AppColors.criticalRed,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _MapBadge(
              icon: Icons.sensors_rounded,
              label: 'Live',
              color: AppColors.safeGreen,
            ),
          ),
          _MapPin(
            leftPercent: 0.70,
            topPercent: 0.36,
            icon: Icons.personal_injury_rounded,
            label: 'Victim',
            color: AppColors.sosRed,
          ),
          _MapPin(
            leftPercent: 0.25,
            topPercent: 0.72,
            icon: Icons.local_hospital_rounded,
            label: 'Hospital',
            color: AppColors.safeGreen,
          ),
          _MapPin(
            leftPercent: 0.50,
            topPercent: 0.55,
            icon: Icons.volunteer_activism_rounded,
            label: 'Volunteers',
            color: AppColors.warningAmber,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _CoordinateStrip(
              victimLat: victimLat,
              victimLng: victimLng,
              responderLat: responderLat,
              responderLng: responderLng,
            ),
          ),
        ],
      ),
    );
  }

  double _progressFromCoordinates() {
    const startLat = 28.5672;
    const endLat = 28.6139;
    final progress = (responderLat - startLat) / (endLat - startLat);
    return progress.clamp(0.0, 1.0);
  }
}

class _OperationsMapPainter extends CustomPainter {
  final bool isDark;
  final double responderProgress;

  _OperationsMapPainter({
    required this.isDark,
    required this.responderProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF111827), const Color(0xFF172033)]
            : [const Color(0xFFEAF2F8), const Color(0xFFF8FAFC)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = Offset(size.width * 0.70, size.height * 0.36);
    for (final ring in [0.18, 0.31, 0.44]) {
      canvas.drawCircle(
        center,
        min(size.width, size.height) * ring,
        Paint()
          ..color = AppColors.warningAmber.withOpacity(0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF293548) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22;
    final routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    final hospital = Offset(size.width * 0.25, size.height * 0.72);
    final bend = Offset(size.width * 0.25, size.height * 0.36);
    final victim = Offset(size.width * 0.70, size.height * 0.36);

    final route = Path()
      ..moveTo(hospital.dx, hospital.dy)
      ..lineTo(bend.dx, bend.dy)
      ..lineTo(victim.dx, victim.dy);
    canvas.drawPath(route, roadPaint);
    canvas.drawPath(route, routePaint);

    final responder = _routePoint(hospital, bend, victim, responderProgress);
    canvas.drawCircle(
      responder,
      16,
      Paint()
        ..color = AppColors.infoBlue
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      responder,
      24,
      Paint()
        ..color = AppColors.infoBlue.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(responder.dx - 6, responder.dy),
      Offset(responder.dx + 6, responder.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(responder.dx, responder.dy - 6),
      Offset(responder.dx, responder.dy + 6),
      crossPaint,
    );
  }

  Offset _routePoint(Offset hospital, Offset bend, Offset victim, double progress) {
    if (progress < 0.5) {
      final step = progress * 2;
      return Offset(hospital.dx, hospital.dy + (bend.dy - hospital.dy) * step);
    }
    final step = (progress - 0.5) * 2;
    return Offset(bend.dx + (victim.dx - bend.dx) * step, bend.dy);
  }

  @override
  bool shouldRepaint(covariant _OperationsMapPainter oldDelegate) {
    return oldDelegate.responderProgress != responderProgress ||
        oldDelegate.isDark != isDark;
  }
}

class _MapPin extends StatelessWidget {
  final double leftPercent;
  final double topPercent;
  final IconData icon;
  final String label;
  final Color color;

  const _MapPin({
    required this.leftPercent,
    required this.topPercent,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * leftPercent - 24,
                top: constraints.maxHeight * topPercent - 42,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MapBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateStrip extends StatelessWidget {
  final double victimLat;
  final double victimLng;
  final double responderLat;
  final double responderLng;

  const _CoordinateStrip({
    required this.victimLat,
    required this.victimLng,
    required this.responderLat,
    required this.responderLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Victim: ${victimLat.toStringAsFixed(4)}, ${victimLng.toStringAsFixed(4)}'),
            Text('Responder: ${responderLat.toStringAsFixed(4)}, ${responderLng.toStringAsFixed(4)}'),
          ],
        ),
      ),
    );
  }
}
