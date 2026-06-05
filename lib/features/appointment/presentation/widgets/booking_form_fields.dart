library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Renders all core booking form fields including patient ID, appointment type,
/// single/recurring type, date, time and optional notes.
class BookingFormFields extends StatelessWidget {
  /// Creates a [BookingFormFields] widget.
  const BookingFormFields({
    super.key,
    required this.patientIdController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.notesController,
    required this.patientIdValidator,
    required this.dateErrorText,
    required this.timeErrorText,
  });

  /// Text controller for the patient ID input.
  final TextEditingController patientIdController;

  /// Currently selected appointment type.
  final AppointmentType selectedType;

  /// Callback when appointment type is changed.
  final ValueChanged<AppointmentType> onTypeChanged;

  /// Whether recurring appointment booking is active.
  final bool isRecurring;

  /// Callback when recurring toggle status changes.
  final ValueChanged<bool> onRecurringChanged;

  /// Currently selected appointment date.
  final DateTime? selectedDate;

  /// Callback when date is selected.
  final ValueChanged<DateTime> onDateChanged;

  /// Currently selected appointment time.
  final TimeOfDay? selectedTime;

  /// Callback when time is selected.
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// Text controller for appointment notes.
  final TextEditingController notesController;

  /// Form validator for patient ID field.
  final String? Function(String?)? patientIdValidator;

  /// Validation error text for the date field.
  final String? dateErrorText;

  /// Validation error text for the time field.
  final String? timeErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: patientIdController,
          labelText: AppStrings.patientId,
          hintText: 'Enter 36-character UUID',
          validator: patientIdValidator,
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          AppStrings.appointmentType,
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        Row(
          children: AppointmentType.values.map((type) {
            final bool isSelected = selectedType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                child: OutlinedButton(
                  onPressed: () => onTypeChanged(type),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: AppSizes.borderWidth,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                  ),
                  child: Text(
                    type.displayLabel,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Checkbox(
              value: isRecurring,
              onChanged: (val) => onRecurringChanged(val ?? false),
              activeColor: AppColors.primary,
            ),
            GestureDetector(
              onTap: () => onRecurringChanged(!isRecurring),
              child: Text(
                AppStrings.isRecurring,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Expanded(
              child: _buildPickerField(
                context: context,
                label: isRecurring ? 'Start Date' : AppStrings.selectDate,
                valueText: selectedDate != null
                    ? Formatters.formatDateShort(selectedDate!)
                    : 'Select Date',
                icon: Icons.calendar_today,
                errorText: dateErrorText,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    onDateChanged(picked);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: _buildPickerField(
                context: context,
                label: AppStrings.selectTime,
                valueText: selectedTime != null
                    ? Formatters.formatTime(DateTime(2026, 1, 1, selectedTime!.hour, selectedTime!.minute))
                    : 'Select Time',
                icon: Icons.access_time,
                errorText: timeErrorText,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    onTimeChanged(picked);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: notesController,
          labelText: AppStrings.notes,
          hintText: 'Add notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required BuildContext context,
    required String label,
    required String valueText,
    required IconData icon,
    required String? errorText,
    required VoidCallback onTap,
  }) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12,
              vertical: AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconDefault, color: AppColors.textMuted),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    valueText,
                    style: AppTextStyles.body.copyWith(
                      color: valueText.startsWith('Select')
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSizes.p4),
          Text(
            errorText,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
