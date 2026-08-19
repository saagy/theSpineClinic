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
    required this.onChooseDate,
    required this.onFilterDoctor,
  });

  final DateTime date;
  final Staff? doctor;
  final VoidCallback onChooseDate;
  final VoidCallback onFilterDoctor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide =
            constraints.maxWidth >= AppSizes.appointmentWorkspaceBreakpoint;
        final Widget dateControl = _DateNavigator(
          date: date,
          onChoose: onChooseDate,
        );
        final Widget doctorControl = _DoctorControl(
          doctor: doctor,
          onTap: onFilterDoctor,
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
    required this.onChoose,
  });

  final DateTime date;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppSizes.borderRadiusInput,
        side: BorderSide(color: colors.outline),
      ),
      child: InkWell(
        onTap: onChoose,
        borderRadius: AppSizes.borderRadiusInput,
        child: SizedBox(
          height: AppSizes.inputHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: AppSizes.iconSmall,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Text(
                    DateFormat('EEE, MMM d').format(date),
                    style: AppTextStyles.bodyBold,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorControl extends StatelessWidget {
  const _DoctorControl({
    required this.doctor,
    required this.onTap,
  });
  final Staff? doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
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
    );
  }
}
