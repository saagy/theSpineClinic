/// Searchable patient selection bottom sheet for the new-appointment flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_patient_search_provider.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';

/// Bottom sheet that lets the user search and pick a patient with bounded queries.
class PatientSearchSheet extends ConsumerStatefulWidget {
  /// Creates a [PatientSearchSheet].
  const PatientSearchSheet({super.key, required this.onSelected});

  /// Called when the user taps a patient row.
  final ValueChanged<Patient> onSelected;

  @override
  ConsumerState<PatientSearchSheet> createState() => _PatientSearchSheetState();
}

class _PatientSearchSheetState extends ConsumerState<PatientSearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<Patient>> listAsync = ref.watch(bookingPatientSearchProvider(_q));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: AppSizes.p12),
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(AppSizes.r4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p20,
              AppSizes.p16,
              AppSizes.p20,
              AppSizes.p12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.selectPatient, style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSizes.p12),
                AppSearchBar(
                  hintText: AppStrings.searchPatientHint,
                  onChanged: (v) => setState(() => _q = v),
                  onClear: () => setState(() => _q = ''),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: cs.primary),
              ),
              error: (_, __) => Center(
                child: Text(
                  AppStrings.errorLoadingPatients,
                  style: AppTextStyles.bodySecondary.copyWith(color: cs.error),
                ),
              ),
              data: (patients) {
                if (patients.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noPatientsFound,
                      style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1.0,
                    thickness: AppSizes.borderWidth,
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                  itemBuilder: (_, i) {
                    final p = patients[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p4,
                      ),
                      leading: PatientMonogramBadge(name: p.fullName, size: 36.0),
                      title: Text(p.fullName, style: AppTextStyles.bodyBold),
                      subtitle: Text(
                        p.phoneNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => widget.onSelected(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
