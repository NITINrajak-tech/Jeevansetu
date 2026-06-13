import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/mock/mock_data.dart';

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
  final String? otpCode;
  final String? errorMessage;
  final bool hasGpsPermission;
  final bool hasSensorsPermission;
  final bool hasNotificationsPermission;

  AuthState({
    required this.status,
    this.user,
    this.phoneNumber,
    this.otpCode,
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
    String? otpCode,
    String? errorMessage,
    bool? hasGpsPermission,
    bool? hasSensorsPermission,
    bool? hasNotificationsPermission,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpCode: otpCode ?? this.otpCode,
      errorMessage: errorMessage ?? this.errorMessage,
      hasGpsPermission: hasGpsPermission ?? this.hasGpsPermission,
      hasSensorsPermission: hasSensorsPermission ?? this.hasSensorsPermission,
      hasNotificationsPermission:
          hasNotificationsPermission ?? this.hasNotificationsPermission,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(status: AuthStatus.unauthenticated));

  void requestOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate API delay
    state = state.copyWith(
      status: AuthStatus.otpVerification,
      phoneNumber: phone,
      otpCode: '123456', // Hardcoded mock OTP
    );
  }

  bool verifyOtp(String enteredCode) {
    if (enteredCode == '123456' || enteredCode == '1234') {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: MockData.mockUser,
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Invalid OTP code. Please try again.');
      return false;
    }
  }

  void signup(String name, String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 1500));
    final newUser = UserModel(
      uid: 'user_new',
      name: name,
      phone: phone,
      avatarUrl: '',
      isMonitoringActive: true,
      currentLatitude: 28.6139,
      currentLongitude: 77.2090,
      locationAddress: 'New Delhi, India',
      preferredLanguage: 'English',
    );
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: newUser,
    );
  }

  void logout() {
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
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
