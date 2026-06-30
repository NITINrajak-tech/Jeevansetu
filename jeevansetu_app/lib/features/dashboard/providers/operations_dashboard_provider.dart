import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/gov_api.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class OperationsDashboardState {
  const OperationsDashboardState({
    required this.isLoading,
    this.payload,
    this.errorMessage,
    this.lastUpdated,
    this.isLive = false,
  });

  final bool isLoading;
  final Map<String, dynamic>? payload;
  final String? errorMessage;
  final DateTime? lastUpdated;

  /// True when connected via WebSocket (live stream).
  final bool isLive;

  OperationsDashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? payload,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? lastUpdated,
    bool? isLive,
  }) {
    return OperationsDashboardState(
      isLoading: isLoading ?? this.isLoading,
      payload: payload ?? this.payload,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLive: isLive ?? this.isLive,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OperationsDashboardNotifier
    extends StateNotifier<OperationsDashboardState> {
  OperationsDashboardNotifier({GovApi? api})
      : _api = api ?? GovApi(),
        super(const OperationsDashboardState(isLoading: true));

  final GovApi _api;
  Timer? _pollTimer;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    // First load from HTTP so we have data immediately.
    await refresh();
    // Then try to upgrade to WebSocket for live updates.
    _connectWebSocket();
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    try {
      final base = AppConstants.backendBaseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final uri = Uri.parse('$base/gov/ws');

      _wsChannel = WebSocketChannel.connect(uri);
      _wsSub = _wsChannel!.stream.listen(
        _onWsMessage,
        onError: _onWsError,
        onDone: _onWsDone,
      );

      state = state.copyWith(isLive: true, clearErrorMessage: true);
    } catch (_) {
      // WebSocket unavailable — fall back to HTTP polling.
      _startPolling();
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      // Merge incoming event into existing payload.
      final merged = <String, dynamic>{
        ...?state.payload,
        ...data,
      };
      state = state.copyWith(
        isLoading: false,
        payload: merged,
        lastUpdated: DateTime.now(),
        isLive: true,
        clearErrorMessage: true,
      );
    } catch (_) {
      // Ignore malformed messages.
    }
  }

  void _onWsError(Object error) {
    state = state.copyWith(
      isLive: false,
      errorMessage: 'Live feed error — switching to polling.',
    );
    _startPolling();
  }

  void _onWsDone() {
    state = state.copyWith(isLive: false);
    // Reconnect after a delay.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _connectWebSocket();
    });
  }

  // ── HTTP Polling (fallback) ───────────────────────────────────────────────

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      refresh();
    });
  }

  Future<void> refresh() async {
    state =
        state.copyWith(isLoading: state.payload == null, clearErrorMessage: true);
    try {
      final payload = await _api.fetchOperationsDashboard();
      state = state.copyWith(
        isLoading: false,
        payload: payload,
        lastUpdated: DateTime.now(),
        clearErrorMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final operationsDashboardProvider = StateNotifierProvider.autoDispose<
    OperationsDashboardNotifier, OperationsDashboardState>((ref) {
  final notifier = OperationsDashboardNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});