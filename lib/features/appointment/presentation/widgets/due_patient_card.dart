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
    required this.onTap,
  });

  final Patient patient;
  final DateTime referenceDate;
  final VoidCallback onCall;
  final VoidCallback onBook;
  final VoidCallback onRemindLater;
  final VoidCallback onStopFollowUp;
  final VoidCallback onTap;

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
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: [ClinicColors.of(context).cardShadow],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Material(
            color: colors.surface,
            child: InkWell(
              onTap: onTap,
              splashColor: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
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
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: colors.onSurfaceVariant,
                            size: AppSizes.iconDefault,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: AppSizes.iconDefault,
                          color: colors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
                          ),
                          elevation: 2,
                          position: PopupMenuPosition.under,
                          onSelected: (action) => switch (action) {
                            DuePatientMenuAction.remindLater => onRemindLater(),
                            DuePatientMenuAction.stopFollowUp => onStopFollowUp(),
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: DuePatientMenuAction.remindLater,
                              height: AppSizes.buttonHeightSmall,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: colors.primary,
                                    size: AppSizes.iconSmall,
                                  ),
                                  const SizedBox(width: AppSizes.p8),
                                  Text(
                                    AppStrings.remindLater,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: DuePatientMenuAction.stopFollowUp,
                              height: AppSizes.buttonHeightSmall,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block_outlined,
                                    color: colors.error,
                                    size: AppSizes.iconSmall,
                                  ),
                                  const SizedBox(width: AppSizes.p8),
                                  Text(
                                    AppStrings.stopFollowUp,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colors.error,
                                    ),
                                  ),
                                ],
                              ),
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
            ),
          ),
        ),
      ),
    );
  }
}
