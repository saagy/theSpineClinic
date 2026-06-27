/// Overflow menu for deleting an appointment from the detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/delete_appointment_button.dart';

class DetailOverflowButton extends ConsumerWidget {
  const DetailOverflowButton({
    super.key,
    required this.appointment,
  });
  final dynamic appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      padding: const EdgeInsets.only(right: AppSizes.p8),
      constraints: const BoxConstraints(),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'delete') {
          await deleteAppointmentWithConfirmation(context, ref, appointment);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: AppSizes.p8),
              Text(AppStrings.deleteAppointment,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
