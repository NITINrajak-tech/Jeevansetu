import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jeevansetu_app/core/theme/app_colors.dart';
import 'package:jeevansetu_app/core/theme/app_text_styles.dart';
import 'package:jeevansetu_app/core/widgets/gradient_card.dart';
import 'package:jeevansetu_app/data/models/contact_model.dart';
import 'package:jeevansetu_app/features/emergency/providers/emergency_provider.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  ContactPriority _selectedPriority = ContactPriority.family;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();
    _selectedPriority = ContactPriority.family;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              title: const Text('Add Emergency Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _relationController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Priority Tag:',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        DropdownButton<ContactPriority>(
                          value: _selectedPriority,
                          dropdownColor: isDark ? AppColors.surfaceDarkCard : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          onChanged: (ContactPriority? val) {
                            if (val != null) {
                              setDialogState(() {
                                _selectedPriority = val;
                              });
                            }
                          },
                          items: ContactPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.name.toUpperCase()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                      final newContact = ContactModel(
                        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                        name: _nameController.text,
                        phone: '+91 ${_phoneController.text}',
                        relationship: _relationController.text,
                        priority: _selectedPriority,
                        avatarText: _nameController.text.substring(0, 2).toUpperCase(),
                      );
                      ref.read(emergencyProvider.notifier).addContact(newContact);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact added successfully!'),
                          backgroundColor: AppColors.safeGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Contact'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Your Guardians',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: isDark ? Colors.white : AppColors.primaryLight,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = state.contacts[index];

                    return Dismissible(
                      key: Key(contact.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.sosRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.sosRed, size: 28),
                      ),
                      onDismissed: (_) {
                        ref.read(emergencyProvider.notifier).deleteContact(contact.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${contact.name} removed.'),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: AppColors.accent,
                              onPressed: () {
                                ref.read(emergencyProvider.notifier).addContact(contact);
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GradientCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              // Avatar circle
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _getPriorityColor(contact.priority).withOpacity(0.15),
                                child: Text(
                                  contact.avatarText,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _getPriorityColor(contact.priority),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          contact.name,
                                          style: AppTextStyles.cardTitle.copyWith(
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPriorityChip(contact.priority),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${contact.relationship} • ${contact.phone}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(ContactPriority priority) {
    switch (priority) {
      case ContactPriority.family:
        return AppColors.sosRed;
      case ContactPriority.friend:
        return AppColors.warningAmber;
      case ContactPriority.doctor:
        return AppColors.primary;
      default:
        return AppColors.textSecondaryDark;
    }
  }

  Widget _buildPriorityChip(ContactPriority priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
