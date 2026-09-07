import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Top header for receptionist dashboard featuring branch context, date, and "+ New Appointment" CTA.
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  _BranchDropdown(clinic: clinic)
                else
                  Text(
                    clinic.displayLabel,
                    style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface),
                  ),
                const SizedBox(height: AppSizes.p2),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newAppointment),
            icon: const Icon(LucideIcons.plus, size: 16.0),
            label: Text(AppStrings.newAppointment, style: AppTextStyles.bodyBold),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
            ),
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
        side: BorderSide(color: cs.outlineVariant.withAlpha(120), width: AppSizes.borderWidth),
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
          Icon(LucideIcons.chevron_down, size: 16.0, color: cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withAlpha(100),
              width: AppSizes.borderWidth,
            ),
          ),
        ),
        child: TabBar(
          controller: controller,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13.5),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13.5),
          indicatorColor: cs.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: AppStrings.schedule),
            Tab(text: AppStrings.booking),
            Tab(text: AppStrings.all),
          ],
        ),
      ),
    );
  }
}
