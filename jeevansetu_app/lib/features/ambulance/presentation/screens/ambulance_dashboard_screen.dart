import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../data/services/ambulance_api.dart';
import '../../../../data/services/gov_api.dart';

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
  final _api = AmbulanceApi();
  final _govApi = GovApi();

  Map<String, dynamic>? _etaResponse;
  List<Map<String, dynamic>> _ambulances = [];
  List<Map<String, dynamic>> _activeAccidents = [];
  String? _selectedAccidentId;
  String? _selectedAmbulanceId;
  String? _message;
  bool _busy = false;
  bool _loadingAmbulances = false;
  bool _loadingAccidents = false;
  Timer? _etaPollTimer;
  late final TabController _tabController;
  late final MapController _mapController;

  LatLng _ambulanceLoc = const LatLng(28.6100, 77.2050);
  LatLng _incidentLoc = LatLng(
    AppConstants.mockLatitude,
    AppConstants.mockLongitude,
  );
  LatLng _hospitalLoc = const LatLng(28.6220, 77.2100);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mapController = MapController();
    _loadData();
  }

  @override
  void dispose() {
    _etaPollTimer?.cancel();
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await Future.wait([_loadAmbulances(), _loadActiveAccidents()]);
  }

  Future<void> _loadAmbulances() async {
    setState(() => _loadingAmbulances = true);
    try {
      final data = await _api.listAmbulances();
      if (!mounted) return;
      setState(() {
        _ambulances = data;
        if (_selectedAmbulanceId == null) {
          final available = data.where(
            (a) => (a['status'] ?? 'available') == 'available',
          );
          if (available.isNotEmpty) {
            _selectedAmbulanceId = available.first['id']?.toString();
          }
        }
      });
    } catch (_) {
      // Ignore — show empty state.
    } finally {
      if (mounted) setState(() => _loadingAmbulances = false);
    }
  }

  Future<void> _loadActiveAccidents() async {
    setState(() => _loadingAccidents = true);
    try {
      final payload = await _govApi.fetchOperationsDashboard();
      final operations = payload['operations'] as Map<String, dynamic>?;
      final incidents = (operations?['active_incidents'] as List<dynamic>? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) return;
      setState(() {
        _activeAccidents = incidents;
        if (_selectedAccidentId == null && incidents.isNotEmpty) {
          _selectedAccidentId = incidents.first['incident_id']?.toString();
          _applyIncidentToMap(incidents.first);
        }
      });
    } catch (_) {
      // Non-gov users may not have access — keep manual entry fallback.
    } finally {
      if (mounted) setState(() => _loadingAccidents = false);
    }
  }

  void _applyIncidentToMap(Map<String, dynamic> incident) {
    final lat = (incident['latitude'] as num?)?.toDouble();
    final lng = (incident['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    setState(() {
      _incidentLoc = LatLng(lat, lng);
    });
    _mapController.move(_incidentLoc, _mapController.camera.zoom);
  }

  void _onAccidentSelected(String? incidentId) {
    if (incidentId == null) return;
    final incident = _activeAccidents.firstWhere(
      (item) => item['incident_id']?.toString() == incidentId,
      orElse: () => const {},
    );
    setState(() => _selectedAccidentId = incidentId);
    if (incident.isNotEmpty) {
      _applyIncidentToMap(incident);
    }
  }

  void _applyEtaToMap(Map<String, dynamic> response) {
    if (response['ambulance_lat'] != null && response['ambulance_lng'] != null) {
      _ambulanceLoc = LatLng(
        (response['ambulance_lat'] as num).toDouble(),
        (response['ambulance_lng'] as num).toDouble(),
      );
    }
    if (response['incident_lat'] != null && response['incident_lng'] != null) {
      _incidentLoc = LatLng(
        (response['incident_lat'] as num).toDouble(),
        (response['incident_lng'] as num).toDouble(),
      );
    }
    if (response['hospital_lat'] != null && response['hospital_lng'] != null) {
      _hospitalLoc = LatLng(
        (response['hospital_lat'] as num).toDouble(),
        (response['hospital_lng'] as num).toDouble(),
      );
    }
    _mapController.move(_ambulanceLoc, _mapController.camera.zoom);
  }

  Future<void> _fetchEta() async {
    final accidentId = _selectedAccidentId;
    if (accidentId == null || accidentId.isEmpty) {
      setState(() => _message = 'Select an active accident first.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _api.getEta(accidentId);
      if (!mounted) return;
      setState(() {
        _etaResponse = response;
        _applyEtaToMap(response);
      });
      _startEtaPolling(accidentId);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startEtaPolling(String accidentId) {
    _etaPollTimer?.cancel();
    _etaPollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        final response = await _api.getEta(accidentId);
        if (!mounted) return;
        setState(() {
          _etaResponse = response;
          _applyEtaToMap(response);
        });
      } catch (_) {
        // Keep last known ETA on transient errors.
      }
    });
  }

  Future<void> _dispatch() async {
    final accidentId = _selectedAccidentId;
    final ambulanceId = _selectedAmbulanceId;
    if (accidentId == null || accidentId.isEmpty) {
      setState(() => _message = 'Select an active accident first.');
      return;
    }
    if (ambulanceId == null || ambulanceId.isEmpty) {
      setState(() => _message = 'Select an available ambulance first.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _api.dispatch(
        ambulanceId: ambulanceId,
        accidentId: accidentId,
      );
      if (!mounted) return;
      setState(() {
        _etaResponse = response;
        _message = '✓ Ambulance dispatched successfully.';
      });
      await _fetchEta();
      _tabController.animateTo(0);
      await _loadAmbulances();
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh fleet & incidents',
            onPressed: _busy ? null : _loadData,
          ),
        ],
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
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
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
                      Polyline(
                        points: [_ambulanceLoc, _incidentLoc],
                        color: const Color(0xFFFB8C00),
                        strokeWidth: 4,
                      ),
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
        Expanded(
          flex: 45,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildEtaStrip(isDark, titleColor, subtitleColor),
                const SizedBox(height: 12),
                _buildActiveAccidentsList(isDark, titleColor, subtitleColor),
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
                style:
                    AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    final eta = _etaResponse!['eta_minutes'] ?? _etaResponse!['eta'] ?? '—';
    final status = _etaResponse!['status'] ?? 'dispatched';
    final distance =
        _etaResponse!['distance_km'] ?? _etaResponse!['distance'] ?? '—';

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
                Text('Distance: $distance km',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
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

  Widget _buildActiveAccidentsList(
      bool isDark, Color titleColor, Color subtitleColor) {
    if (_loadingAccidents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activeAccidents.isEmpty) {
      return GradientCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No active accidents from backend. Use the Dispatch tab to enter an incident ID manually.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Accidents',
            style: AppTextStyles.cardTitle.copyWith(color: titleColor)),
        const SizedBox(height: 8),
        for (final incident in _activeAccidents)
          _accidentTile(incident, isDark, titleColor),
      ],
    );
  }

  Widget _accidentTile(
      Map<String, dynamic> incident, bool isDark, Color titleColor) {
    final id = incident['incident_id']?.toString() ?? '—';
    final severity = incident['severity']?.toString() ?? 'Unknown';
    final isSelected = _selectedAccidentId == id;

    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () => _onAccidentSelected(id),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isSelected ? Colors.redAccent : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('$severity • ${incident['victim_status'] ?? 'pending'}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.2, duration: 200.ms);
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
    final id = amb['id']?.toString() ?? '';
    final isAvailable = status == 'available';
    final isSelected = _selectedAmbulanceId == id;

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
                    setState(() => _selectedAmbulanceId = id);
                    _tabController.animateTo(1);
                  }
                : null,
            child: Text(isSelected
                ? 'Selected'
                : isAvailable
                    ? 'Select'
                    : 'Busy'),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.2, duration: 200.ms);
  }

  // ── Dispatch Tab ──────────────────────────────────────────────────────────

  Widget _buildDispatchTab(bool isDark, Color titleColor, Color subtitleColor) {
    final availableAmbulances = _ambulances
        .where((a) => (a['status'] ?? 'available') == 'available')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispatch Center',
              style: AppTextStyles.screenTitle.copyWith(color: titleColor)),
          const SizedBox(height: 6),
          Text(
            'Choose an active accident and available ambulance from the backend.',
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
                DropdownButtonFormField<String>(
                  value: _selectedAccidentId,
                  dropdownColor: AppColors.surfaceDarkElevated,
                  decoration: const InputDecoration(
                    labelText: 'Active Accident',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  items: [
                    if (_activeAccidents.isEmpty && _selectedAccidentId != null)
                      DropdownMenuItem(
                        value: _selectedAccidentId,
                        child: Text(_selectedAccidentId!),
                      ),
                    for (final incident in _activeAccidents)
                      DropdownMenuItem(
                        value: incident['incident_id']?.toString(),
                        child: Text(
                          '${incident['incident_id']} • ${incident['severity'] ?? 'Unknown'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loadingAccidents ? null : _onAccidentSelected,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedAmbulanceId,
                  dropdownColor: AppColors.surfaceDarkElevated,
                  decoration: const InputDecoration(
                    labelText: 'Available Ambulance',
                    prefixIcon: Icon(Icons.local_taxi_rounded),
                  ),
                  items: [
                    if (availableAmbulances.isEmpty &&
                        _selectedAmbulanceId != null)
                      DropdownMenuItem(
                        value: _selectedAmbulanceId,
                        child: Text(_selectedAmbulanceId!),
                      ),
                    for (final amb in availableAmbulances)
                      DropdownMenuItem(
                        value: amb['id']?.toString(),
                        child: Text(
                          '${amb['license_plate'] ?? amb['id']} • ${amb['status'] ?? 'available'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loadingAmbulances
                      ? null
                      : (value) => setState(() => _selectedAmbulanceId = value),
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
