import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'package:spine_clinic_app/shared/widgets/form_columns.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_controls.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_patient_field.dart';
export 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_controls.dart'
    show SegmentedAppointmentTypeSelector;

class BookingFormFields extends StatelessWidget {
  const BookingFormFields({
    super.key,
    this.preselectedPatient,
    this.onPatientTap,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.dateErrorText,
    required this.timeErrorText,
    this.showRecurringToggle = true,
    this.enabled = true,
  });

  final Patient? preselectedPatient;
  final VoidCallback? onPatientTap;
  final AppointmentType selectedType;
  final ValueChanged<AppointmentType> onTypeChanged;
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final String? dateErrorText;
  final String? timeErrorText;
  final bool showRecurringToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormSection(
        title: AppStrings.patient,
        child: BookingPatientField(
          patient: preselectedPatient,
          onSelect: enabled ? onPatientTap : null,
        ),
      ),
      const SizedBox(height: AppSizes.p20),
      FormSection(
        title: AppStrings.appointmentType,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedAppointmentTypeSelector(
              selectedType: selectedType,
              onTypeChanged: onTypeChanged,
              enabled: enabled,
            ),
            const SizedBox(height: AppSizes.p20),
            FormColumns(
              breakpoint: AppSizes.formControlPairBreakpoint,
              first: BookingPickerField(
                label: isRecurring ? AppStrings.startDate : AppStrings.selectDate,
                value: selectedDate == null
                    ? AppStrings.select
                    : DateFormat.yMMMd().format(selectedDate!),
                icon: Icons.calendar_today_outlined,
                error: dateErrorText,
                onTap: enabled ? () => _pickDate(context) : null,
              ),
              second: BookingPickerField(
                label: AppStrings.selectTime,
                value: selectedTime?.format(context) ?? AppStrings.select,
                icon: Icons.schedule,
                error: timeErrorText,
                onTap: enabled ? () => _pickTime(context) : null,
              ),
            ),
            if (showRecurringToggle) ...[
              const SizedBox(height: AppSizes.p12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(AppStrings.recurringBooking),
                value: isRecurring,
                onChanged: enabled ? (value) => onRecurringChanged(value ?? false) : null,
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) onTimeChanged(picked);
  }
}
