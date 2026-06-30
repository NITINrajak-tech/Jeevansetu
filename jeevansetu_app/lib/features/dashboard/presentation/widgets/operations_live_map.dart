import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final center = LatLng(victimLat, victimLng);
    final routePoints = [
      LatLng(responderLat, responderLng),
      LatLng(victimLat, victimLng),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14.2,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jeevansetu.app',
                  maxNativeZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    _buildMarker(
                      point: LatLng(victimLat, victimLng),
                      color: AppColors.sosRed,
                      icon: Icons.personal_injury_rounded,
                      label: 'Victim',
                    ),
                    _buildMarker(
                      point:
                          LatLng(victimLat + 0.0012, victimLng - 0.0015),
                      color: AppColors.warningAmber,
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Volunteer',
                    ),
                    _buildMarker(
                      point: LatLng(responderLat, responderLng),
                      color: AppColors.infoBlue,
                      icon: Icons.local_taxi_rounded,
                      label: 'Ambulance',
                    ),
                    _buildMarker(
                      point:
                          LatLng(victimLat - 0.0025, victimLng + 0.0021),
                      color: AppColors.safeGreen,
                      icon: Icons.local_hospital_rounded,
                      label: 'Hospital',
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors',
                        onTap: () {}),
                  ],
                ),
              ],
            ),
          ),

          // ── Severity badge ───────────────────────────────────────────────
          Positioned(
            left: 16,
            top: 16,
            child: _MapBadge(
              icon: Icons.warning_rounded,
              label: severity,
              color: AppColors.criticalRed,
            ),
          ),

          // ── Live indicator ───────────────────────────────────────────────
          Positioned(
            right: 16,
            top: 16,
            child: _MapBadge(
              icon: Icons.sensors_rounded,
              label: 'Live',
              color: AppColors.safeGreen,
            ),
          ),

          // ── Coordinates strip ────────────────────────────────────────────
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

  Marker _buildMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Marker(
      width: 80,
      height: 64,
      point: point,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.78),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

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
        style: const TextStyle(
            color: Colors.white, fontSize: 11, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Victim: ${victimLat.toStringAsFixed(4)}, ${victimLng.toStringAsFixed(4)}'),
            Text(
                'Responder: ${responderLat.toStringAsFixed(4)}, ${responderLng.toStringAsFixed(4)}'),
          ],
        ),
      ),
    );
  }
}
