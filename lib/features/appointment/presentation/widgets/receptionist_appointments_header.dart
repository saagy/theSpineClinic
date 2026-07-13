import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

class ReceptionistAppointmentsHeader extends StatelessWidget {
  const ReceptionistAppointmentsHeader({
    required this.clinic,
    required this.isAdmin,
    super.key,
  });

  final ClinicLocation clinic;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isAdmin)
            _BranchDropdown(clinic: clinic)
          else
            Text(
              clinic.displayLabel,
              style: AppTextStyles.headingMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          Text(
            DateFormat('E, MMM d').format(DateTime.now()),
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _BranchDropdown extends ConsumerWidget {
  const _BranchDropdown({required this.clinic});

  final ClinicLocation clinic;

  static const Map<String, ClinicLocation> _dbToEnum = {
    'tagamoa': ClinicLocation.tagamoa,
    'masr_elgedida': ClinicLocation.masrElgedida,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminBranch = ref.watch(adminBranchFilterProvider);
    final String display = adminBranch == null
        ? AppStrings.allBranches
        : _dbToEnum[adminBranch]?.displayLabel ?? clinic.displayLabel;

    return PopupMenuButton<String>(
      offset: const Offset(0, AppSizes.p40),
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      onSelected: (String value) => _selectBranch(ref, value),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(
            AppStrings.allBranches,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        ...ClinicLocation.values.map(
          (ClinicLocation location) => PopupMenuItem<String>(
            value: location.dbValue,
            child: Text(
              location.displayLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            display,
            style: AppTextStyles.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSizes.p4),
          Icon(
            Icons.arrow_drop_down_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class ReceptionistAppointmentsTabStrip extends StatelessWidget {
  const ReceptionistAppointmentsTabStrip({required this.controller, super.key});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: controller,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: AppTextStyles.bodyBold,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: AppStrings.today),
          Tab(text: AppStrings.booking),
          Tab(text: AppStrings.all),
        ],
      ),
    );
  }
}
