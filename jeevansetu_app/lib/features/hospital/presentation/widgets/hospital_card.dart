import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../data/models/hospital_model.dart';

class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: GradientCard(
        borderColor: isSelected ? AppColors.primary : null,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Best choice tag row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hospital.isBestChoice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.safeGreen, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'BEST RECOMMENDATION',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.safeGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(),
                // Trauma level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primaryLight : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hospital.traumaLevel.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hospital title
            Text(
              hospital.name,
              style: AppTextStyles.cardTitle.copyWith(
                color: isDark ? Colors.white : AppColors.primaryLight,
              ),
            ),

            const SizedBox(height: 14),

            // Distance & ETA Row
            Row(
              children: [
                _buildInfoTag(context, Icons.timer_rounded, '${hospital.etaMinutes} mins', AppColors.sosRed),
                const SizedBox(width: 12),
                _buildInfoTag(context, Icons.directions_car_rounded, '${hospital.distanceKm} km', AppColors.primary),
                const SizedBox(width: 12),
                _buildInfoTag(context, Icons.bed_rounded, '${hospital.availableBeds} beds', AppColors.safeGreen),
              ],
            ),

            const SizedBox(height: 16),

            // CTA Navigate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: const Text('Navigate to Center'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(BuildContext context, IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
