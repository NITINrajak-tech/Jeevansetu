import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/mock/mock_data.dart';

class HospitalState {
  final List<HospitalModel> hospitals;
  final HospitalModel? recommendedHospital;
  final HospitalModel? selectedHospital;

  HospitalState({
    required this.hospitals,
    this.recommendedHospital,
    this.selectedHospital,
  });

  HospitalState copyWith({
    List<HospitalModel>? hospitals,
    HospitalModel? recommendedHospital,
    HospitalModel? selectedHospital,
  }) {
    return HospitalState(
      hospitals: hospitals ?? this.hospitals,
      recommendedHospital: recommendedHospital ?? this.recommendedHospital,
      selectedHospital: selectedHospital ?? this.selectedHospital,
    );
  }
}

class HospitalNotifier extends StateNotifier<HospitalState> {
  HospitalNotifier()
      : super(HospitalState(
          hospitals: MockData.mockHospitals,
          recommendedHospital: MockData.mockHospitals.firstWhere((h) => h.isBestChoice),
          selectedHospital: MockData.mockHospitals.firstWhere((h) => h.isBestChoice),
        ));

  void selectHospital(HospitalModel hospital) {
    state = state.copyWith(selectedHospital: hospital);
  }

  void filterHospitals(double maxDistance) {
    final filteredList = MockData.mockHospitals.where((h) => h.distanceKm <= maxDistance).toList();
    state = state.copyWith(hospitals: filteredList);
  }

  void resetFilters() {
    state = state.copyWith(hospitals: MockData.mockHospitals);
  }
}

final hospitalProvider =
    StateNotifierProvider<HospitalNotifier, HospitalState>((ref) {
  return HospitalNotifier();
});
