import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TrackingStatus {
  dispatching,
  enRoute,
  arrived,
}

class TrackingState {
  final TrackingStatus status;
  final int etaMinutes;
  final double distanceKm;
  final String hospitalName;
  final double ambulanceLat;
  final double ambulanceLng;

  TrackingState({
    required this.status,
    required this.etaMinutes,
    required this.distanceKm,
    required this.hospitalName,
    required this.ambulanceLat,
    required this.ambulanceLng,
  });

  TrackingState copyWith({
    TrackingStatus? status,
    int? etaMinutes,
    double? distanceKm,
    String? hospitalName,
    double? ambulanceLat,
    double? ambulanceLng,
  }) {
    return TrackingState(
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      hospitalName: hospitalName ?? this.hospitalName,
      ambulanceLat: ambulanceLat ?? this.ambulanceLat,
      ambulanceLng: ambulanceLng ?? this.ambulanceLng,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  Timer? _movementTimer;
  double _step = 0.0;

  TrackingNotifier()
      : super(TrackingState(
          status: TrackingStatus.dispatching,
          etaMinutes: 7,
          distanceKm: 2.4,
          hospitalName: 'AIIMS Trauma Centre',
          ambulanceLat: 28.5672,
          ambulanceLng: 77.2100,
        ));

  void startSimulatingTracking() {
    _step = 0.0;
    _movementTimer?.cancel();
    state = state.copyWith(
      status: TrackingStatus.dispatching,
      etaMinutes: 7,
      distanceKm: 2.4,
    );

    // Dynamic en-route simulation
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _step += 0.15;
      if (_step >= 1.0) {
        timer.cancel();
        state = state.copyWith(
          status: TrackingStatus.arrived,
          etaMinutes: 0,
          distanceKm: 0.0,
          // Ambulance arrived at CP user position
          ambulanceLat: 28.6139,
          ambulanceLng: 77.2090,
        );
      } else {
        // Interpolate between AIIMS (28.5672, 77.2100) and CP (28.6139, 77.2090)
        final nextLat = 28.5672 + (28.6139 - 28.5672) * _step;
        final nextLng = 77.2100 + (77.2090 - 77.2100) * _step;
        final eta = (7 * (1.0 - _step)).round();
        final distance = 2.4 * (1.0 - _step);

        state = state.copyWith(
          status: TrackingStatus.enRoute,
          etaMinutes: eta > 0 ? eta : 1,
          distanceKm: double.parse(distance.toStringAsFixed(1)),
          ambulanceLat: nextLat,
          ambulanceLng: nextLng,
        );
      }
    });
  }

  void selectHospital(String name, double lat, double lng) {
    state = state.copyWith(
      hospitalName: name,
      ambulanceLat: lat,
      ambulanceLng: lng,
    );
    startSimulatingTracking();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});
