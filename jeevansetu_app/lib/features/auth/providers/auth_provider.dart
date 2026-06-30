import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_api.dart';
import '../../../data/services/device_token_service.dart';

enum AuthStatus {
  unauthenticated,
  otpVerification,
  authenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? phoneNumber;
  final String? errorMessage;
  final bool hasGpsPermission;
  final bool hasSensorsPermission;
  final bool hasNotificationsPermission;

  AuthState({
    required this.status,
    this.user,
    this.phoneNumber,
    this.errorMessage,
    this.hasGpsPermission = false,
    this.hasSensorsPermission = false,
    this.hasNotificationsPermission = false,
  });

  bool get allPermissionsGranted =>
      hasGpsPermission && hasSensorsPermission && hasNotificationsPermission;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? phoneNumber,
    String? errorMessage,
    bool? hasGpsPermission,
    bool? hasSensorsPermission,
    bool? hasNotificationsPermission,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage ?? this.errorMessage,
      hasGpsPermission: hasGpsPermission ?? this.hasGpsPermission,
      hasSensorsPermission: hasSensorsPermission ?? this.hasSensorsPermission,
      hasNotificationsPermission:
          hasNotificationsPermission ?? this.hasNotificationsPermission,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    AuthApi? authApi,
    DeviceTokenService? deviceTokenService,
  })  : _authApi = authApi ?? AuthApi(),
        _deviceTokenService = deviceTokenService ?? DeviceTokenService(),
        super(AuthState(status: AuthStatus.unauthenticated));

  final AuthApi _authApi;
  final DeviceTokenService _deviceTokenService;

  /// Derive a stable email from phone number for backend compatibility.
  String _emailFromPhone(String phone) =>
      '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@jeevansetu.local';

  static const _defaultPassword = 'JeevanSetu123!';

  // ── OTP Flow ─────────────────────────────────────────────────────────────

  void requestOtp(String phone) {
    state = state.copyWith(
      status: AuthStatus.otpVerification,
      phoneNumber: phone,
      errorMessage: null,
    );
  }

  /// Verifies OTP. For now uses simple client-side check (1234 / 123456).
  /// On success, attempts login then register against real backend.
  Future<bool> verifyOtp(String enteredCode) async {
    if (enteredCode != '123456' && enteredCode != '1234') {
      state = state.copyWith(errorMessage: 'Invalid OTP. Please try again.');
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final phone = state.phoneNumber ?? '';
    final email = _emailFromPhone(phone);

    try {
      // Try login first; if 401/404 → register new account.
      Map<String, dynamic> data;
      try {
        data = await _authApi.login(
          emailOrPhone: email,
          password: _defaultPassword,
        );
      } on AuthApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 404 || e.statusCode == 422) {
          // User doesn't exist yet — auto-register.
          data = await _authApi.register(
            name: 'User $phone',
            phone: phone,
            email: email,
            password: _defaultPassword,
          );
        } else {
          rethrow;
        }
      }

      await _handleAuthSuccess(data, phone: phone);
      return true;
    } on AuthApiException catch (e) {
      // Fallback to offline mode if backend is unreachable.
      if (e.statusCode == 0 || e.statusCode >= 500) {
        _handleOfflineFallback(phone);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.otpVerification,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      // Network error — allow offline mode.
      _handleOfflineFallback(phone);
      return true;
    }
  }

  // ── Signup Flow ───────────────────────────────────────────────────────────

  Future<void> signup(String name, String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final email = _emailFromPhone(phone);

    try {
      final data = await _authApi.register(
        name: name,
        phone: phone,
        email: email,
        password: _defaultPassword,
      );
      await _handleAuthSuccess(data, phone: phone, name: name);
    } on AuthApiException catch (e) {
      if (e.statusCode == 0 || e.statusCode >= 500) {
        _handleOfflineFallback(phone, name: name);
        return;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (_) {
      _handleOfflineFallback(phone, name: name);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _handleAuthSuccess(
    Map<String, dynamic> data, {
    required String phone,
    String? name,
  }) async {
    final token = data['access_token'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;

    // Store JWT globally so all API clients pick it up.
    AppConstants.backendAuthToken = token;

    final user = UserModel(
      uid: userJson?['id']?.toString() ?? phone,
      name: userJson?['name'] as String? ?? name ?? 'User',
      phone: phone,
      avatarUrl: '',
      isMonitoringActive: true,
      currentLatitude: 28.6139,
      currentLongitude: 77.2090,
      locationAddress: 'India',
      preferredLanguage: 'English',
    );

    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      errorMessage: null,
    );

    await _syncFcmToken();
  }

  void _handleOfflineFallback(String phone, {String? name}) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: UserModel(
        uid: 'offline_$phone',
        name: name ?? 'User $phone',
        phone: phone,
        avatarUrl: '',
        isMonitoringActive: true,
        currentLatitude: 28.6139,
        currentLongitude: 77.2090,
        locationAddress: 'India',
        preferredLanguage: 'English',
      ),
    );
  }

  Future<void> _syncFcmToken() async {
    try {
      final fcmToken = await _deviceTokenService.getToken();
      if (fcmToken != null && AppConstants.backendAuthToken.isNotEmpty) {
        await _deviceTokenService.syncTokenToBackend(token: fcmToken);
      }
    } catch (_) {
      // Best-effort — do not block auth flow.
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  void logout() {
    AppConstants.backendAuthToken = '';
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void toggleGpsPermission() {
    state = state.copyWith(hasGpsPermission: !state.hasGpsPermission);
  }

  void toggleSensorsPermission() {
    state = state.copyWith(hasSensorsPermission: !state.hasSensorsPermission);
  }

  void toggleNotificationsPermission() {
    state = state.copyWith(
        hasNotificationsPermission: !state.hasNotificationsPermission);
  }

  void grantAllPermissions() {
    state = state.copyWith(
      hasGpsPermission: true,
      hasSensorsPermission: true,
      hasNotificationsPermission: true,
    );
    _syncFcmToken();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
