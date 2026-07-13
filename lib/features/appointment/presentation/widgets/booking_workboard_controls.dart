import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

class BookingWorkboardControls extends StatelessWidget {
  const BookingWorkboardControls({
    super.key,
    required this.date,
    required this.doctor,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onChooseDate,
    required this.onFilterDoctor,
    this.onReplaceDoctor,
  });

  final DateTime date;
  final Staff? doctor;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onChooseDate;
  final VoidCallback onFilterDoctor;
  final VoidCallback? onReplaceDoctor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide =
            constraints.maxWidth >= AppSizes.appointmentWorkspaceBreakpoint;
        final Widget dateControl = _DateNavigator(
          date: date,
          onPrevious: onPreviousDay,
          onNext: onNextDay,
          onChoose: onChooseDate,
        );
        final Widget doctorControl = _DoctorControl(
          doctor: doctor,
          onTap: onFilterDoctor,
          onReplace: onReplaceDoctor,
        );
        if (wide) {
          return Row(
            children: [
              Expanded(child: dateControl),
              const SizedBox(width: AppSizes.p16),
              Expanded(child: doctorControl),
            ],
          );
        }
        return Column(
          children: [
            dateControl,
            const SizedBox(height: AppSizes.p12),
            doctorControl,
          ],
        );
      },
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onChoose,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSizes.borderRadiusInput,
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.previousDay,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: onChoose,
              child: Center(
                child: Text(
                  DateFormat('EEE, MMM d').format(date),
                  style: AppTextStyles.bodyBold,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextDay,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _DoctorControl extends StatelessWidget {
  const _DoctorControl({
    required this.doctor,
    required this.onTap,
    this.onReplace,
  });
  final Staff? doctor;
  final VoidCallback onTap;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusInput,
              side: BorderSide(color: colors.outline),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: AppSizes.borderRadiusInput,
              child: SizedBox(
                height: AppSizes.inputHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
                  child: Row(
                    children: [
                      if (doctor != null) ...[
                        AppAvatar(
                          name: doctor!.fullName,
                          radius: AppSizes.avatarSmall / 2,
                        ),
                        const SizedBox(width: AppSizes.p12),
                      ] else
                        const Icon(Icons.filter_list_rounded),
                      Expanded(
                        child: Text(
                          doctor?.fullName ?? AppStrings.allDoctors,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.tune_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onReplace != null) ...[
          const SizedBox(width: AppSizes.p8),
          FilledButton.tonalIcon(
            onPressed: onReplace,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text(AppStrings.replaceDoctor),
          ),
        ],
      ],
    );
  }
}
