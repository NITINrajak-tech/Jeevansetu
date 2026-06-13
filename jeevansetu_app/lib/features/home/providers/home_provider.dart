import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/mock/mock_data.dart';

class HomeState {
  final bool isMonitoring;
  final List<ActivityModel> activities;
  final String currentAddress;

  HomeState({
    required this.isMonitoring,
    required this.activities,
    required this.currentAddress,
  });

  HomeState copyWith({
    bool? isMonitoring,
    List<ActivityModel>? activities,
    String? currentAddress,
  }) {
    return HomeState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      activities: activities ?? this.activities,
      currentAddress: currentAddress ?? this.currentAddress,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier()
      : super(HomeState(
          isMonitoring: true,
          activities: MockData.mockActivities,
          currentAddress: MockData.mockUser.locationAddress,
        ));

  void toggleMonitoring() {
    final newState = !state.isMonitoring;
    final log = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: newState ? 'Monitoring Resumed' : 'Monitoring Paused',
      description: newState
          ? 'High-frequency crash detection monitoring activated.'
          : 'Crash detection paused by user command.',
      timestamp: DateTime.now(),
      activityType: 'monitoring',
    );

    state = state.copyWith(
      isMonitoring: newState,
      activities: [log, ...state.activities],
    );
  }

  void updateLocation(String newAddress) {
    state = state.copyWith(currentAddress: newAddress);
  }

  void addActivity(ActivityModel activity) {
    state = state.copyWith(
      activities: [activity, ...state.activities],
    );
  }

  void clearActivities() {
    state = state.copyWith(activities: []);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
