import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A live OpenStreetMap map widget that shows victim, responders, and hospital.
/// Replaces the old CustomPainter placeholder.
class MapPlaceholder extends StatefulWidget {
  const MapPlaceholder({
    super.key,
    this.victimLatitude = 28.6139,
    this.victimLongitude = 77.2090,
    this.hospitalLatitude = 28.6220,
    this.hospitalLongitude = 77.2100,
    this.responderLocations = const [],
    this.ambulanceLocations = const [],
    this.showRoute = true,
  });

  final double victimLatitude;
  final double victimLongitude;
  final double hospitalLatitude;
  final double hospitalLongitude;

  /// List of [lat, lng] pairs for volunteer responders.
  final List<List<double>> responderLocations;

  /// List of [lat, lng] pairs for ambulances.
  final List<List<double>> ambulanceLocations;

  final bool showRoute;

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _victim => LatLng(widget.victimLatitude, widget.victimLongitude);
  LatLng get _hospital =>
      LatLng(widget.hospitalLatitude, widget.hospitalLongitude);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _victim,
          initialZoom: 14,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // ── Base tile layer (OpenStreetMap) ──────────────────────────────
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jeevansetu.app',
            maxNativeZoom: 19,
          ),

          // ── Route polyline ───────────────────────────────────────────────
          if (widget.showRoute)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_victim, _hospital],
                  strokeWidth: 4,
                  color: Colors.redAccent.withOpacity(0.85),
                  isDotted: false,
                ),
              ],
            ),

          // ── Markers ───────────────────────────────────────────────────────
          MarkerLayer(
            markers: [
              // Victim
              _buildMarker(
                point: _victim,
                color: const Color(0xFFE53935),
                icon: Icons.personal_injury_rounded,
                label: 'Victim',
              ),

              // Hospital
              _buildMarker(
                point: _hospital,
                color: const Color(0xFF00897B),
                icon: Icons.local_hospital_rounded,
                label: 'Hospital',
              ),

              // Volunteer responders
              for (final loc in widget.responderLocations)
                _buildMarker(
                  point: LatLng(loc[0], loc[1]),
                  color: const Color(0xFF1E88E5),
                  icon: Icons.directions_run_rounded,
                  label: 'Responder',
                ),

              // Ambulances
              for (final loc in widget.ambulanceLocations)
                _buildMarker(
                  point: LatLng(loc[0], loc[1]),
                  color: const Color(0xFFFB8C00),
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Ambulance',
                ),
            ],
          ),

          // ── Attribution ───────────────────────────────────────────────────
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () {},
              ),
            ],
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
      point: point,
      width: 48,
      height: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
