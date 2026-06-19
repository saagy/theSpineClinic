/// Searchable patient selection bottom sheet for the new-appointment flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';

/// Bottom sheet that lets the user search and pick a patient.
class PatientSearchSheet extends ConsumerStatefulWidget {
  /// Creates a [PatientSearchSheet].
  const PatientSearchSheet({super.key, required this.onSelected});

  /// Called when the user taps a patient row.
  final ValueChanged<Patient> onSelected;

  @override
  ConsumerState<PatientSearchSheet> createState() =>
      _PatientSearchSheetState();
}

class _PatientSearchSheetState extends ConsumerState<PatientSearchSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(patientListProvider);
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
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
                Text('Select Patient', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSizes.p12),
                TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _q = v),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone…',
                    hintStyle: AppTextStyles.bodySecondary,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary,
                        size: AppSizes.iconDefault),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: AppSizes.paddingCell,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (_, __) =>
                  const Center(child: Text('Error loading patients')),
              data: (patients) {
                final filtered = _q.isEmpty
                    ? patients
                    : patients
                        .where((p) =>
                            p.fullName
                                .toLowerCase()
                                .contains(_q.toLowerCase()) ||
                            p.phoneNumber.contains(_q))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No patients found'));
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 18,
                        child: Text(
                          p.fullName[0].toUpperCase(),
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      title: Text(p.fullName, style: AppTextStyles.bodyBold),
                      subtitle: Text(
                        p.phoneNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
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
