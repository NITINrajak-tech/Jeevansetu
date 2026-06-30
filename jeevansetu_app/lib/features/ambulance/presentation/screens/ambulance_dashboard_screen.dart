import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../data/services/ambulance_api.dart';

// ── Ambulance Dashboard Screen ────────────────────────────────────────────────

class AmbulanceDashboardScreen extends ConsumerStatefulWidget {
  const AmbulanceDashboardScreen({super.key});

  @override
  ConsumerState<AmbulanceDashboardScreen> createState() =>
      _AmbulanceDashboardScreenState();
}

class _AmbulanceDashboardScreenState
    extends ConsumerState<AmbulanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _ambulanceIdController = TextEditingController(
      text: '00000000-0000-0000-0000-000000000001');
  final _accidentIdController = TextEditingController(text: 'INC001');
  final _api = AmbulanceApi();

  Map<String, dynamic>? _etaResponse;
  List<Map<String, dynamic>> _ambulances = [];
  String? _message;
  bool _busy = false;
  bool _loadingAmbulances = false;
  late final TabController _tabController;

  // Mock coordinates — will come from API response in production.
  LatLng _ambulanceLoc = const LatLng(28.6100, 77.2050);
  LatLng _incidentLoc = const LatLng(28.6139, 77.2090);
  LatLng _hospitalLoc = const LatLng(28.6220, 77.2100);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAmbulances();
  }

  @override
  void dispose() {
    _ambulanceIdController.dispose();
    _accidentIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadAmbulances() async {
    setState(() => _loadingAmbulances = true);
    try {
      final data = await _api.listAmbulances();
      setState(() => _ambulances = data);
    } catch (_) {
      // Ignore — show empty state.
    } finally {
      if (mounted) setState(() => _loadingAmbulances = false);
    }
  }

  Future<void> _fetchEta() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _api.getEta(_accidentIdController.text.trim());
      setState(() {
        _etaResponse = response;
        // Update map locations from response if available.
        if (response['ambulance_lat'] != null) {
          _ambulanceLoc = LatLng(
            (response['ambulance_lat'] as num).toDouble(),
            (response['ambulance_lng'] as num).toDouble(),
          );
        }
        if (response['incident_lat'] != null) {
          _incidentLoc = LatLng(
            (response['incident_lat'] as num).toDouble(),
            (response['incident_lng'] as num).toDouble(),
          );
        }
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dispatch() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _api.dispatch(
        ambulanceId: _ambulanceIdController.text.trim(),
        accidentId: _accidentIdController.text.trim(),
      );
      setState(() {
        _etaResponse = response;
        _message = '✓ Ambulance dispatched successfully.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final titleColor = isDark ? Colors.white : AppColors.primaryLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Dispatch'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded), text: 'Live Map'),
            Tab(icon: Icon(Icons.airport_shuttle_rounded), text: 'Dispatch'),
          ],
        ),
      ),
      body: Container(
        color: bg,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMapTab(isDark, titleColor, subtitleColor),
              _buildDispatchTab(isDark, titleColor, subtitleColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── Map Tab ───────────────────────────────────────────────────────────────

  Widget _buildMapTab(bool isDark, Color titleColor, Color subtitleColor) {
    return Column(
      children: [
        // Map fills top 55% of screen.
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _incidentLoc,
                  initialZoom: 14,
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
                      // Ambulance → Incident
                      Polyline(
                        points: [_ambulanceLoc, _incidentLoc],
                        color: const Color(0xFFFB8C00),
                        strokeWidth: 4,
                      ),
                      // Incident → Hospital
                      Polyline(
                        points: [_incidentLoc, _hospitalLoc],
                        color: Colors.redAccent,
                        strokeWidth: 4,
                        isDotted: true,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      _marker(_ambulanceLoc, Icons.airport_shuttle_rounded,
                          const Color(0xFFFB8C00), 'Ambulance'),
                      _marker(_incidentLoc, Icons.personal_injury_rounded,
                          const Color(0xFFE53935), 'Victim'),
                      _marker(_hospitalLoc, Icons.local_hospital_rounded,
                          const Color(0xFF00897B), 'Hospital'),
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
          ),
        ),

        // ETA info strip.
        Expanded(
          flex: 45,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildEtaStrip(isDark, titleColor, subtitleColor),
                const SizedBox(height: 12),
                _buildAmbulanceList(isDark, titleColor, subtitleColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _marker(LatLng point, IconData icon, Color color, String label) {
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
                  color: color.withOpacity(0.5),
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
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaStrip(bool isDark, Color titleColor, Color subtitleColor) {
    if (_etaResponse == null) {
      return GradientCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dispatch an ambulance to see live ETA and route on the map.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    final eta = _etaResponse!['eta_minutes'] ?? _etaResponse!['eta'] ?? '—';
    final status = _etaResponse!['status'] ?? 'dispatched';

    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$eta',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ETA: $eta min',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                _statusBadge(status),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 250.ms);
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'dispatched':
        color = Colors.orange;
        break;
      case 'en_route':
        color = Colors.blue;
        break;
      case 'arrived':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAmbulanceList(
      bool isDark, Color titleColor, Color subtitleColor) {
    if (_loadingAmbulances) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ambulances.isEmpty) {
      return GradientCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No ambulances registered. Add one via admin panel.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fleet', style: AppTextStyles.cardTitle.copyWith(color: titleColor)),
        const SizedBox(height: 8),
        for (final amb in _ambulances) _ambulanceTile(amb, isDark),
      ],
    );
  }

  Widget _ambulanceTile(Map<String, dynamic> amb, bool isDark) {
    final status = amb['status'] ?? 'available';
    final plate = amb['license_plate'] ?? amb['id'] ?? '—';
    final isAvailable = status == 'available';

    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.airport_shuttle_rounded,
            color: isAvailable ? Colors.greenAccent : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plate.toString(),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(status.toString().toUpperCase(),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white54)),
              ],
            ),
          ),
          TextButton(
            onPressed: isAvailable
                ? () {
                    _ambulanceIdController.text = amb['id'].toString();
                    _tabController.animateTo(1);
                  }
                : null,
            child: Text(isAvailable ? 'Dispatch' : 'Busy'),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.2, duration: 200.ms);
  }

  // ── Dispatch Tab ──────────────────────────────────────────────────────────

  Widget _buildDispatchTab(bool isDark, Color titleColor, Color subtitleColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispatch Center',
              style: AppTextStyles.screenTitle.copyWith(color: titleColor)),
          const SizedBox(height: 6),
          Text(
            'Enter the accident ID and ambulance UUID to dispatch.',
            style: AppTextStyles.bodyMedium.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: 20),
          GradientCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incident & Unit',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: _accidentIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Accident ID',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ambulanceIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ambulance UUID',
                    prefixIcon: Icon(Icons.local_taxi_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _fetchEta,
                        icon: const Icon(Icons.route_rounded),
                        label: const Text('Get ETA'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _dispatch,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Dispatch'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _message!.startsWith('✓')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _message!.startsWith('✓')
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
              child: Text(
                _message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _message!.startsWith('✓')
                      ? Colors.greenAccent
                      : AppColors.sosRed,
                ),
              ),
            ).animate().fade(duration: 250.ms),
            const SizedBox(height: 12),
          ],
          if (_etaResponse != null) ...[
            GradientCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Response Details',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  for (final entry in _etaResponse!.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text('${entry.key}: ',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white54)),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ).animate().fade(duration: 250.ms),
          ],
        ],
      ),
    );
  }
}