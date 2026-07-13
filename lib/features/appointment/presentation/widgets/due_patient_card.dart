import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

enum DuePatientMenuAction { remindLater, stopFollowUp }

class DuePatientCard extends StatelessWidget {
  const DuePatientCard({
    super.key,
    required this.patient,
    required this.referenceDate,
    required this.onCall,
    required this.onBook,
    required this.onRemindLater,
    required this.onStopFollowUp,
  });

  final Patient patient;
  final DateTime referenceDate;
  final VoidCallback onCall;
  final VoidCallback onBook;
  final VoidCallback onRemindLater;
  final VoidCallback onStopFollowUp;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime? due = patient.nextVisitDate;
    final bool overdue =
        due != null &&
        DateUtils.dateOnly(due).isBefore(DateUtils.dateOnly(referenceDate));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
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
                                ? ClinicColors.of(context).warning
                                : colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<DuePatientMenuAction>(
                  onSelected: (action) => switch (action) {
                    DuePatientMenuAction.remindLater => onRemindLater(),
                    DuePatientMenuAction.stopFollowUp => onStopFollowUp(),
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: DuePatientMenuAction.remindLater,
                      child: Text(AppStrings.remindLater),
                    ),
                    PopupMenuItem(
                      value: DuePatientMenuAction.stopFollowUp,
                      child: Text(AppStrings.stopFollowUp),
                    ),
                  ],
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
        ),
      ),
    );
  }
}
