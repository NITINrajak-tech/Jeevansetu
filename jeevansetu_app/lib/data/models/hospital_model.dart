class HospitalModel {
  final String id;
  final String name;
  final double distanceKm;
  final int etaMinutes;
  final String traumaLevel; // e.g., 'Level 1 Trauma Center'
  final double latitude;
  final double longitude;
  final int availableBeds;
  final int availableVentilators;
  final bool isBestChoice;

  HospitalModel({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.etaMinutes,
    required this.traumaLevel,
    required this.latitude,
    required this.longitude,
    required this.availableBeds,
    required this.availableVentilators,
    this.isBestChoice = false,
  });
}
