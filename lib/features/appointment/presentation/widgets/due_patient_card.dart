import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/schedule_density_controller.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

part 'due_patient_card_compact.dart';
part 'due_patient_card_menu.dart';

/// Patient card for the booking workboard (due patients), supporting both
/// standard density (full actions) and compact density (single-row quick actions).
class DuePatientCard extends ConsumerWidget {
  const DuePatientCard({
    super.key,
    required this.patient,
    required this.referenceDate,
    required this.onCall,
    required this.onBook,
    required this.onRemindLater,
    required this.onStopFollowUp,
    required this.onTap,
    this.isCompact,
  });

  final Patient patient;
  final DateTime referenceDate;
  final VoidCallback onCall;
  final VoidCallback onBook;
  final VoidCallback onRemindLater;
  final VoidCallback onStopFollowUp;
  final VoidCallback onTap;

  /// Optional override for compact vs standard density.
  final bool? isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool compact =
        isCompact ?? ref.watch(scheduleCompactControllerProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final DateTime? due = patient.nextVisitDate;
    final bool overdue =
        due != null &&
        DateUtils.dateOnly(due).isBefore(DateUtils.dateOnly(referenceDate));

    final double radius = compact ? AppSizes.r12 : AppSizes.r16;
    final EdgeInsets internalPadding = compact
        ? const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: 6.0)
        : const EdgeInsets.all(AppSizes.p16);
    final EdgeInsets margin = compact
        ? const EdgeInsets.only(bottom: AppSizes.p4)
        : const EdgeInsets.only(bottom: AppSizes.p12);

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          border: Border.all(
            color: colors.outlineVariant,
            width: AppSizes.borderWidth,
          ),
          boxShadow: [clinic.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          child: Material(
            color: colors.surface,
            child: InkWell(
              onTap: onTap,
              splashColor: colors.primaryContainer,
              child: Padding(
                padding: internalPadding,
                child: compact
                    ? _DuePatientCompactRow(
                        patient: patient,
                        due: due,
                        overdue: overdue,
                        colors: colors,
                        clinic: clinic,
                        onCall: onCall,
                        onBook: onBook,
                        onRemindLater: onRemindLater,
                        onStopFollowUp: onStopFollowUp,
                      )
                    : _buildStandardContent(
                        context,
                        colors,
                        clinic,
                        due,
                        overdue,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardContent(
    BuildContext context,
    ColorScheme colors,
    ClinicColors clinic,
    DateTime? due,
    bool overdue,
  ) {
    return Column(
      children: [
        Row(
          children: [
            AppAvatar(
              name: patient.fullName,
              radius: AppSizes.avatarSmall / 2,
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(patient.phoneNumber, style: AppTextStyles.caption),
                  if (due != null)
                    Text(
                      overdue
                          ? AppStrings.overdueSince(
                              DateFormat('MMM d').format(due),
                            )
                          : AppStrings.dueOn(
                              DateFormat('MMM d').format(due),
                            ),
                      style: AppTextStyles.caption.copyWith(
                        color: overdue
                            ? clinic.warning
                            : colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            _DuePatientMenu(
              onRemindLater: onRemindLater,
              onStopFollowUp: onStopFollowUp,
              isCompact: false,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                labelText: AppStrings.call,
                icon: Icons.call_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: onCall,
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: AppButton(
                labelText: AppStrings.book,
                icon: Icons.event_available_rounded,
                onPressed: onBook,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
