import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Flat, responsive record with readable identity and contact details.
class StaffAccountTile extends StatelessWidget {
  const StaffAccountTile({
    super.key,
    required this.staff,
    this.onTap,
    this.showCreatedDate = false,
    this.action,
  });
  final Staff staff;
  final VoidCallback? onTap;
  final bool showCreatedDate;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final role = switch (staff.role) {
      UserRole.superAdmin => AppStrings.superAdmin,
      UserRole.doctor => staff.isSenior ? AppStrings.seniorDoctor : AppStrings.doctor,
      UserRole.receptionist => AppStrings.receptionist,
    };
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSizes.paddingCell,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppSizes.staffWideBreakpoint &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.fullName,
                    style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    staff.email,
                    style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (staff.phone?.trim().isNotEmpty ?? false)
                    Text(
                      Formatters.formatPhone(staff.phone!),
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  if (!wide) ...[
                    const SizedBox(height: AppSizes.p8),
                    Wrap(
                      spacing: AppSizes.p12,
                      runSpacing: AppSizes.p4,
                      children: [_role(context, role), if (!showCreatedDate) _status(context)],
                    ),
                  ],
                  if (showCreatedDate) ...[
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      AppStrings.staffAppliedOn(staff.createdAt.toShortDateString()),
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(child: MediaQuery.withNoTextScaling(child:
                    PatientMonogramBadge(name: staff.fullName, size: AppSizes.avatarSmall))),
                      const SizedBox(width: AppSizes.p12),
                      Expanded(child: identity),
                      if (wide) ...[
                        const SizedBox(width: AppSizes.p24),
                        SizedBox(width: AppSizes.staffRoleColumnWidth, child: _role(context, role)),
                        const SizedBox(width: AppSizes.p16),
                        if (action != null)
                          action!
                        else
                          SizedBox(width: AppSizes.staffStatusColumnWidth, child: _status(context)),
                      ],
                      if (onTap != null) ...[
                        const SizedBox(width: AppSizes.p8),
                        Icon(
                          Icons.chevron_right,
                          size: AppSizes.iconDefault,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  if (!wide && action != null) ...[
                    const SizedBox(height: AppSizes.p12),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _role(BuildContext context, String role) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        role,
        style: AppTextStyles.captionBold.copyWith(color: Theme.of(context).colorScheme.onSurface),
      ),
      if (staff.role == UserRole.receptionist)
        Text(
          staff.branch?.displayLabel ?? AppStrings.noBranch,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );

  Widget _status(BuildContext context) => Text(
    staff.accountStatus.label,
    style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}
