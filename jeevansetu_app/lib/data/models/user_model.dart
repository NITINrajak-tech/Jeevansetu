class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String avatarUrl;
  final bool isMonitoringActive;
  final double currentLatitude;
  final double currentLongitude;
  final String locationAddress;
  final String preferredLanguage;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.isMonitoringActive,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.locationAddress,
    required this.preferredLanguage,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? avatarUrl,
    bool? isMonitoringActive,
    double? currentLatitude,
    double? currentLongitude,
    String? locationAddress,
    String? preferredLanguage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMonitoringActive: isMonitoringActive ?? this.isMonitoringActive,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      locationAddress: locationAddress ?? this.locationAddress,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
