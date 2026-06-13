enum ContactPriority {
  family,
  friend,
  doctor,
  other,
}

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final ContactPriority priority;
  final String avatarText;

  ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
    required this.avatarText,
  });

  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    ContactPriority? priority,
    String? avatarText,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      avatarText: avatarText ?? this.avatarText,
    );
  }
}
