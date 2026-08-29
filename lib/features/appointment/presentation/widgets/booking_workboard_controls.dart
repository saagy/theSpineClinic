import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_filter_tile.dart';

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
        final Widget doctorControl = DoctorFilterTile(
          selectedDoctor: doctor,
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
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onChoose,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: AppSizes.iconDefault,
                color: colors.primary,
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  DateFormat('EEE, MMM d').format(date),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: AppSizes.iconDefault,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
