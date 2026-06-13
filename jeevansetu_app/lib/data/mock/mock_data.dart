import '../models/user_model.dart';
import '../models/contact_model.dart';
import '../models/hospital_model.dart';
import '../models/activity_model.dart';

class MockData {
  MockData._();

  static UserModel mockUser = UserModel(
    uid: 'user_123',
    name: 'Aarav Sharma',
    phone: '+91 98765 43210',
    avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=150&q=80',
    isMonitoringActive: true,
    currentLatitude: 28.6139,
    currentLongitude: 77.2090,
    locationAddress: 'Connaught Place, New Delhi, India',
    preferredLanguage: 'English',
  );

  static List<ContactModel> mockContacts = [
    ContactModel(
      id: 'c1',
      name: 'Sunita Sharma',
      phone: '+91 98765 00001',
      relationship: 'Mother',
      priority: ContactPriority.family,
      avatarText: 'MS',
    ),
    ContactModel(
      id: 'c2',
      name: 'Rajesh Sharma',
      phone: '+91 98765 00002',
      relationship: 'Father',
      priority: ContactPriority.family,
      avatarText: 'FS',
    ),
    ContactModel(
      id: 'c3',
      name: 'Vikram Malhotra',
      phone: '+91 98765 00003',
      relationship: 'Friend',
      priority: ContactPriority.friend,
      avatarText: 'VM',
    ),
  ];

  static List<HospitalModel> mockHospitals = [
    HospitalModel(
      id: 'h1',
      name: 'AIIMS Trauma Centre',
      distanceKm: 2.4,
      etaMinutes: 7,
      traumaLevel: 'Level 1 Trauma Center',
      latitude: 28.5672,
      longitude: 77.2100,
      availableBeds: 14,
      availableVentilators: 5,
      isBestChoice: true,
    ),
    HospitalModel(
      id: 'h2',
      name: 'Safdarjung Hospital Emergency',
      distanceKm: 2.8,
      etaMinutes: 9,
      traumaLevel: 'Level 1 Trauma Center',
      latitude: 28.5660,
      longitude: 77.2070,
      availableBeds: 8,
      availableVentilators: 2,
    ),
    HospitalModel(
      id: 'h3',
      name: 'Max Super Speciality Hospital',
      distanceKm: 5.2,
      etaMinutes: 14,
      traumaLevel: 'Level 2 Trauma Center',
      latitude: 28.5421,
      longitude: 77.2215,
      availableBeds: 22,
      availableVentilators: 8,
    ),
    HospitalModel(
      id: 'h4',
      name: 'Fortis Hospital Okhla',
      distanceKm: 8.1,
      etaMinutes: 21,
      traumaLevel: 'Level 2 Trauma Center',
      latitude: 28.5580,
      longitude: 77.2831,
      availableBeds: 18,
      availableVentilators: 4,
    ),
  ];

  static List<ActivityModel> mockActivities = [
    ActivityModel(
      id: 'act1',
      title: 'Drive Started',
      description: 'System automatically activated high-frequency monitoring.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      activityType: 'monitoring',
    ),
    ActivityModel(
      id: 'act2',
      title: 'System Calibration',
      description: 'Accelerometer & Gyroscope sensors calibrated successfully.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      activityType: 'system',
    ),
    ActivityModel(
      id: 'act3',
      title: 'Location Updated',
      description: 'Current coordinate saved: CP, New Delhi.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      activityType: 'system',
    ),
    ActivityModel(
      id: 'act4',
      title: 'Alert Cancelled',
      description: 'False alarm triggered by speed drop; cancelled by user.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      activityType: 'alert',
    ),
  ];
}
