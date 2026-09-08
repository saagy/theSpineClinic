import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_branch_dropdown.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

export 'receptionist_appointments_tab_strip.dart';

/// Top header for receptionist dashboard featuring branch context, date,
/// "+ New Appointment" CTA, and contextual "Replace Doctor" action.
class ReceptionistAppointmentsHeader extends StatelessWidget {
  const ReceptionistAppointmentsHeader({
    required this.clinic,
    required this.isAdmin,
    this.onReplaceDoctor,
    super.key,
  });

  final ClinicLocation clinic;
  final bool isAdmin;
  final VoidCallback? onReplaceDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isWide = MediaQuery.sizeOf(context).width >= 650;

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
                  ReceptionistBranchDropdown(clinic: clinic)
                else
                  Text(
                    clinic.displayLabel,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                const SizedBox(height: AppSizes.p2),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: AppTextStyles.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isWide)
            _buildWideActions(context, cs)
          else
            _buildCompactActions(context, cs),
        ],
      ),
    );
  }

  Widget _buildWideActions(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onReplaceDoctor != null) ...[
          OutlinedButton.icon(
            onPressed: onReplaceDoctor,
            icon: const Icon(LucideIcons.arrow_left_right, size: 14.0),
            label: Text(
              AppStrings.replaceDoctor,
              style: AppTextStyles.captionBold.copyWith(color: cs.onSurface),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p10,
              ),
              minimumSize: const Size(0, 40.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              side: BorderSide(
                color: cs.outlineVariant.withAlpha(140),
                width: AppSizes.borderWidth,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p8),
        ],
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
    );
  }

  Widget _buildCompactActions(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.newAppointment),
          icon: const Icon(LucideIcons.plus, size: 16.0),
          label: Text(AppStrings.newAppointment, style: AppTextStyles.bodyBold),
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p14,
              vertical: AppSizes.p10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
          ),
        ),
        if (onReplaceDoctor != null) ...[
          const SizedBox(width: AppSizes.p4),
          PopupMenuButton<String>(
            tooltip: AppStrings.moreActions,
            icon: Icon(
              LucideIcons.ellipsis_vertical,
              size: 18.0,
              color: cs.onSurfaceVariant,
            ),
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              side: BorderSide(
                color: cs.outlineVariant.withAlpha(120),
                width: AppSizes.borderWidth,
              ),
            ),
            onSelected: (_) => onReplaceDoctor!(),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'replace_doctor',
                height: AppSizes.buttonHeightSmall,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.arrow_left_right,
                      size: 16.0,
                      color: cs.onSurface,
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      AppStrings.replaceDoctor,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

