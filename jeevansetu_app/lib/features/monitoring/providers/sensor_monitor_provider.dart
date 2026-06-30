import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

/// G-force threshold in m/s² that triggers automatic crash detection.
/// 2.5 G ≈ 24.5 m/s². We use 25.0 for a comfortable margin.
const double kCrashGForceThreshold = 25.0;

/// Minimum debounce window so a single event doesn't spam multiple alerts.
const Duration kCrashDebounce = Duration(seconds: 5);

// ── Models ────────────────────────────────────────────────────────────────────

class SensorReading {
  const SensorReading({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;

  /// Euclidean magnitude of the 3-axis vector.
  double get magnitude => sqrt(x * x + y * y + z * z);
}

class SensorMonitorState {
  const SensorMonitorState({
    required this.isMonitoring,
    this.locationPermissionGranted = false,
    this.crashDetected = false,
    this.accelerometer,
    this.gyroscope,
    this.latitude,
    this.longitude,
    this.speedMps,
    this.errorMessage,
  });

  final bool isMonitoring;
  final bool locationPermissionGranted;

  /// Set to true for one frame when a crash event is detected.
  /// The UI should listen and navigate to the accident alert screen.
  final bool crashDetected;

  final SensorReading? accelerometer;
  final SensorReading? gyroscope;
  final double? latitude;
  final double? longitude;
  final double? speedMps;
  final String? errorMessage;

  SensorMonitorState copyWith({
    bool? isMonitoring,
    bool? locationPermissionGranted,
    bool? crashDetected,
    SensorReading? accelerometer,
    SensorReading? gyroscope,
    double? latitude,
    double? longitude,
    double? speedMps,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SensorMonitorState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      crashDetected: crashDetected ?? this.crashDetected,
      accelerometer: accelerometer ?? this.accelerometer,
      gyroscope: gyroscope ?? this.gyroscope,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedMps: speedMps ?? this.speedMps,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SensorMonitorNotifier extends StateNotifier<SensorMonitorState> {
  SensorMonitorNotifier()
      : super(const SensorMonitorState(isMonitoring: false));

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  StreamSubscription<Position>? _positionSub;

  DateTime? _lastCrashTime;

  // ── Location permission ───────────────────────────────────────────────────

  Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(errorMessage: 'Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    state = state.copyWith(
        locationPermissionGranted: granted, clearErrorMessage: true);
    return granted;
  }

  // ── Start / Stop ──────────────────────────────────────────────────────────

  Future<void> startMonitoring() async {
    final granted = await ensureLocationPermission();
    if (!granted) return;

    _accelerometerSub ??= accelerometerEventStream().listen(
      (event) {
        final reading = SensorReading(x: event.x, y: event.y, z: event.z);
        state = state.copyWith(
          accelerometer: reading,
          isMonitoring: true,
          clearErrorMessage: true,
        );
        _evaluateCrash(reading);
      },
      onError: (Object error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    _gyroscopeSub ??= gyroscopeEventStream().listen(
      (event) {
        state = state.copyWith(
          gyroscope: SensorReading(x: event.x, y: event.y, z: event.z),
        );
      },
      onError: (Object error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );
    _positionSub ??=
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        state = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          speedMps: position.speed,
          isMonitoring: true,
          clearErrorMessage: true,
        );
      },
      onError: (Object error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    state = state.copyWith(isMonitoring: true, clearErrorMessage: true);
  }

  Future<void> stopMonitoring() async {
    await _accelerometerSub?.cancel();
    await _gyroscopeSub?.cancel();
    await _positionSub?.cancel();
    _accelerometerSub = null;
    _gyroscopeSub = null;
    _positionSub = null;
    state = state.copyWith(isMonitoring: false);
  }

  // ── Crash Detection ───────────────────────────────────────────────────────

  void _evaluateCrash(SensorReading reading) {
    final magnitude = reading.magnitude;
    if (magnitude < kCrashGForceThreshold) return;

    final now = DateTime.now();
    if (_lastCrashTime != null &&
        now.difference(_lastCrashTime!) < kCrashDebounce) {
      return; // Debounce — ignore rapid repeat events.
    }

    _lastCrashTime = now;

    // Emit crash event. After one frame the UI should read and navigate.
    state = state.copyWith(crashDetected: true);

    // Auto-clear the flag after 100 ms so it can trigger again later.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        state = state.copyWith(crashDetected: false);
      }
    });
  }

  /// Acknowledge the crash so the flag doesn't linger.
  void acknowledgeCrash() {
    state = state.copyWith(crashDetected: false);
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sensorMonitorProvider =
    StateNotifierProvider<SensorMonitorNotifier, SensorMonitorState>((ref) {
  return SensorMonitorNotifier();
});