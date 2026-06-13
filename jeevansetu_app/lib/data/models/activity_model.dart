class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String activityType; // 'monitoring', 'alert', 'sos', 'system'

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.activityType,
  });
}
