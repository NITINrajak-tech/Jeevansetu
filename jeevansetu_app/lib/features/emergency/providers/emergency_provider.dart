import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/mock/mock_data.dart';

enum AccidentStatus {
  none,
  detecting, // showing countdown
  resolvedSafe, // user clicked safe
  confirmed, // countdown hit 0 or manual SOS clicked
}

class EmergencyState {
  final AccidentStatus status;
  final int countdownSeconds;
  final int severityScore;
  final String severityLevel; // 'Critical', 'Moderate', 'Minor'
  final List<ContactModel> contacts;
  final bool isAlertingContacts;
  final String? activeIncidentId;

  EmergencyState({
    required this.status,
    required this.countdownSeconds,
    required this.severityScore,
    required this.severityLevel,
    required this.contacts,
    required this.isAlertingContacts,
    this.activeIncidentId,
  });

  EmergencyState copyWith({
    AccidentStatus? status,
    int? countdownSeconds,
    int? severityScore,
    String? severityLevel,
    List<ContactModel>? contacts,
    bool? isAlertingContacts,
    String? activeIncidentId,
  }) {
    return EmergencyState(
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      severityScore: severityScore ?? this.severityScore,
      severityLevel: severityLevel ?? this.severityLevel,
      contacts: contacts ?? this.contacts,
      isAlertingContacts: isAlertingContacts ?? this.isAlertingContacts,
      activeIncidentId: activeIncidentId ?? this.activeIncidentId,
    );
  }
}

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  Timer? _countdownTimer;

  EmergencyNotifier()
      : super(EmergencyState(
          status: AccidentStatus.none,
          countdownSeconds: 15,
          severityScore: 0,
          severityLevel: 'Safe',
          contacts: MockData.mockContacts,
          isAlertingContacts: false,
        ));

  void startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AccidentStatus.detecting,
      countdownSeconds: 15,
      activeIncidentId: 'INC_${DateTime.now().millisecondsSinceEpoch}',
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } else {
        _countdownTimer?.cancel();
        confirmAccident();
      }
    });
  }

  void cancelAccident() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AccidentStatus.resolvedSafe,
      countdownSeconds: 15,
      activeIncidentId: null,
    );
  }

  void confirmAccident() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AccidentStatus.confirmed,
      countdownSeconds: 0,
      isAlertingContacts: true,
      severityScore: 92, // Mock severity score
      severityLevel: 'Critical',
    );

    // Simulate sending SMS alerts to contacts
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(isAlertingContacts: false);
    });
  }

  // ─── Contacts CRUD ───
  void addContact(ContactModel contact) {
    state = state.copyWith(contacts: [...state.contacts, contact]);
  }

  void updateContact(ContactModel updatedContact) {
    state = state.copyWith(
      contacts: state.contacts.map((c) => c.id == updatedContact.id ? updatedContact : c).toList(),
    );
  }

  void deleteContact(String id) {
    state = state.copyWith(
      contacts: state.contacts.where((c) => c.id != id).toList(),
    );
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>((ref) {
  return EmergencyNotifier();
});
