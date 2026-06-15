import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevansetu_app/core/theme/app_colors.dart';
import 'package:jeevansetu_app/core/theme/app_text_styles.dart';
import 'package:jeevansetu_app/core/router/app_router.dart';
import 'package:jeevansetu_app/features/hospital/presentation/widgets/hospital_card.dart';
import 'package:jeevansetu_app/features/hospital/providers/hospital_provider.dart';
import 'package:jeevansetu_app/features/tracking/providers/tracking_provider.dart';

class HospitalRecommendationScreen extends ConsumerStatefulWidget {
  const HospitalRecommendationScreen({super.key});

  @override
  ConsumerState<HospitalRecommendationScreen> createState() =>
      _HospitalRecommendationScreenState();
}

class _HospitalRecommendationScreenState
    extends ConsumerState<HospitalRecommendationScreen> {
  String _selectedFilter = 'all';

  void _handleNavigate(dynamic hospital) {
    ref.read(trackingProvider.notifier).selectHospital(
          hospital.name,
          hospital.latitude,
          hospital.longitude,
        );
    context.pushNamed(AppRoutes.liveTracking);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var filteredHospitals = state.hospitals;
    if (_selectedFilter == 'close') {
      filteredHospitals = state.hospitals.where((h) => h.distanceKm <= 3.0).toList();
    } else if (_selectedFilter == 'beds') {
      filteredHospitals = state.hospitals.where((h) => h.availableBeds >= 15).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trauma Recommendation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendation Engine',
                      style: AppTextStyles.screenTitle.copyWith(
                        color: isDark ? Colors.white : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Best trauma facilities scored on distance, traffic, trauma level capability, and critical bed availability.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Recommendations', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Under 3.0 km', 'close'),
                      const SizedBox(width: 8),
                      _buildFilterChip('High Bed Availability', 'beds'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Hospitals list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredHospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = filteredHospitals[index];
                    final isSelected = state.selectedHospital?.id == hospital.id;

                    return HospitalCard(
                      hospital: hospital,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(hospitalProvider.notifier).selectHospital(hospital);
                      },
                      onNavigate: () => _handleNavigate(hospital),
                    ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.15, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AppTextStyles.chipText.copyWith(
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: isDark ? AppColors.surfaceDarkCard : Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }
}
