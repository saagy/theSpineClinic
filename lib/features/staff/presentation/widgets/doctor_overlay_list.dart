import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

/// Renders the filtered doctor list inside the dropdown overlay.
class DoctorOverlayList extends ConsumerWidget {
  /// Creates a [DoctorOverlayList].
  const DoctorOverlayList({
    super.key,
    required this.searchQuery,
    required this.selectedDoctors,
    required this.onTap,
  });

  /// The active text search query to filter doctors.
  final String searchQuery;

  /// The currently selected list of doctors.
  final List<Staff> selectedDoctors;

  /// Callback when a doctor row is selected or deselected.
  final ValueChanged<Staff> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeDoctorsProvider);
    return activeAsync.when(
      data: (doctors) {
        final filtered = doctors.where((doc) {
          return doc.fullName.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.p16),
            child: Text(AppStrings.noMatchingDoctorsFound,
                style: AppTextStyles.bodySecondary),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: AppSizes.overlayDropdownMaxHeight),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doctor = filtered[index];
              final isSel = selectedDoctors.any((d) => d.id == doctor.id);

              return ListTile(
                dense: true,
                title: Text(doctor.fullName, style: AppTextStyles.bodyMedium),
                subtitle: Text(doctor.email, style: AppTextStyles.caption),
                trailing: isSel
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => onTap(doctor),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: Center(child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin)),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: Text(AppStrings.errorLoadingDoctors,
            style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}
