import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MapPlaceholder extends StatelessWidget {
  final double ambulanceLat;
  final double ambulanceLng;
  final double userLat;
  final double userLng;

  const MapPlaceholder({
    super.key,
    required this.ambulanceLat,
    required this.ambulanceLng,
    required this.userLat,
    required this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F141C) : const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          // Styled Map Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _MapCanvasPainter(
                isDark: isDark,
                ambulanceLat: ambulanceLat,
                ambulanceLng: ambulanceLng,
                userLat: userLat,
                userLng: userLng,
              ),
            ),
          ),
          // User Location Pin
          _buildMapNode(
            context: context,
            label: 'YOU (Victim)',
            color: AppColors.sosRed,
            icon: Icons.personal_injury_rounded,
            leftPercent: 0.75,
            topPercent: 0.3,
          ),
          // Hospital Node
          _buildMapNode(
            context: context,
            label: 'AIIMS Trauma Center',
            color: AppColors.safeGreen,
            icon: Icons.local_hospital_rounded,
            leftPercent: 0.2,
            topPercent: 0.7,
          ),
        ],
      ),
    );
  }

  Widget _buildMapNode({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required double leftPercent,
    required double topPercent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = constraints.maxWidth * leftPercent - 24;
        final top = constraints.maxHeight * topPercent - 24;

        return Positioned(
          left: left,
          top: top,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final bool isDark;
  final double ambulanceLat;
  final double ambulanceLng;
  final double userLat;
  final double userLng;

  _MapCanvasPainter({
    required this.isDark,
    required this.ambulanceLat,
    required this.ambulanceLng,
    required this.userLat,
    required this.userLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.5;

    // Draw Grid Lines
    const gridSpacing = 30.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw Mock Roads
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    // Hospital point (0.2, 0.7) and User point (0.75, 0.3)
    final pStart = Offset(size.width * 0.2, size.height * 0.7);
    final pCorner = Offset(size.width * 0.2, size.height * 0.3);
    final pEnd = Offset(size.width * 0.75, size.height * 0.3);

    // Draw road borders
    final path = Path()
      ..moveTo(pStart.dx, pStart.dy)
      ..lineTo(pCorner.dx, pCorner.dy)
      ..lineTo(pEnd.dx, pEnd.dy);

    canvas.drawPath(path, roadBorderPaint);
    canvas.drawPath(path, roadPaint);

    // Draw Route Navigation Line (Dashed / Active route)
    final routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, routePaint);

    // Calculate Ambulance Position on the road based on mock coords
    // Map Lat (28.5672 -> 28.6139) to Y coordinate
    // Map Lng (77.2100 -> 77.2090) to X coordinate
    // To make it simple visually, we interpolate on the path:
    final double rangeLat = 28.6139 - 28.5672;
    final double currentStep = (ambulanceLat - 28.5672) / rangeLat;

    Offset ambulancePos;
    if (currentStep < 0.5) {
      // First leg (vertical)
      final stepFactor = currentStep * 2;
      ambulancePos = Offset(pStart.dx, pStart.dy - (pStart.dy - pCorner.dy) * stepFactor);
    } else {
      // Second leg (horizontal)
      final stepFactor = (currentStep - 0.5) * 2;
      ambulancePos = Offset(pCorner.dx + (pEnd.dx - pCorner.dx) * stepFactor, pCorner.dy);
    }

    // Draw Ambulance vehicle indicator
    final ambulancePaint = Paint()
      ..color = AppColors.infoBlue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(ambulancePos, 16, ambulancePaint);

    // Dynamic siren rings
    final sirenPaint = Paint()
      ..color = AppColors.sosRed.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(ambulancePos, 22, sirenPaint);

    // Draw Ambulance Inner Icon Representation (cross)
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(Offset(ambulancePos.dx - 5, ambulancePos.dy), Offset(ambulancePos.dx + 5, ambulancePos.dy), crossPaint);
    canvas.drawLine(Offset(ambulancePos.dx, ambulancePos.dy - 5), Offset(ambulancePos.dx, ambulancePos.dy + 5), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.ambulanceLat != ambulanceLat || oldDelegate.ambulanceLng != ambulanceLng;
  }
}
