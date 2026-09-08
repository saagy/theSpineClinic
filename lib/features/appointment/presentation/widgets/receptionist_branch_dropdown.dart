import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Admin branch selector dropdown for the receptionist dashboard header.
class ReceptionistBranchDropdown extends ConsumerWidget {
  const ReceptionistBranchDropdown({required this.clinic, super.key});

  final ClinicLocation clinic;

  static const Map<String, ClinicLocation> _dbToEnum = {
    'tagamoa': ClinicLocation.tagamoa,
    'masr_elgedida': ClinicLocation.masrElgedida,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final adminBranch = ref.watch(adminBranchFilterProvider);
    final String display = adminBranch == null
        ? AppStrings.allBranches
        : _dbToEnum[adminBranch]?.displayLabel ?? clinic.displayLabel;

    return PopupMenuButton<String>(
      offset: const Offset(0, AppSizes.p32),
      padding: EdgeInsets.zero,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: BorderSide(
          color: cs.outlineVariant.withAlpha(120),
          width: AppSizes.borderWidth,
        ),
      ),
      onSelected: (String value) => _selectBranch(ref, value),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(
            AppStrings.allBranches,
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
          ),
        ),
        ...ClinicLocation.values.map(
          (ClinicLocation loc) => PopupMenuItem<String>(
            value: loc.dbValue,
            child: Text(
              loc.displayLabel,
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            display,
            style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface),
          ),
          const SizedBox(width: AppSizes.p4),
          Icon(
            LucideIcons.chevron_down,
            size: 16.0,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _selectBranch(WidgetRef ref, String value) {
    if (value == '__all__') {
      ref.read(adminBranchFilterProvider.notifier).set(null);
      ref.read(allAppointmentsProvider.notifier).setClinicFilter(null);
    } else if (_dbToEnum[value] != null) {
      ref.read(adminBranchFilterProvider.notifier).set(value);
      ref.read(allAppointmentsProvider.notifier).setClinicFilter(value);
    }
    ref.read(receptionistAppointmentsProvider.notifier).loadToday();
  }
}
