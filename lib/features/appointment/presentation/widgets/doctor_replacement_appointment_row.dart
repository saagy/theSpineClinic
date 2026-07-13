import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';

class DoctorReplacementAppointmentRow extends StatelessWidget {
  const DoctorReplacementAppointmentRow({
    super.key,
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final AppointmentWithPatient item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          onTap: () => onChanged(!selected),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => onChanged(value ?? false),
                ),
                const SizedBox(width: AppSizes.p8),
                SizedBox(
                  width: AppSizes.avatarLarge,
                  child: Text(
                    DateFormat('h:mm a').format(item.appointment.scheduledAt),
                    style: AppTextStyles.captionBold,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.patient.fullName,
                        style: AppTextStyles.bodyBold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.appointment.type.displayLabel,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
