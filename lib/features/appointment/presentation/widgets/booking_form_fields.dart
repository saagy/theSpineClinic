/// Modern booking form fields with patient selector card, responsive card grid
/// selector, and soft-filled input decorations.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Patient selector ──
      _SectionLabel('Patient'),
      const SizedBox(height: AppSizes.p6),
      if (preselectedPatient != null)
        _PatientCard(patient: preselectedPatient!)
      else
        _PatientSearchField(onTap: onPatientTap ?? () {}),
      const SizedBox(height: AppSizes.p16),

      // ── Appointment type — responsive cards grid ──
      _SectionLabel(AppStrings.appointmentType),
      const SizedBox(height: AppSizes.p6),
      LayoutBuilder(
        builder: (context, constraints) {
          final types = AppointmentType.values;
          if (constraints.maxWidth >= 600) {
            return Row(
              children: [
                Expanded(child: _buildTypeCard(context, types[0])),
                const SizedBox(width: AppSizes.p12),
                Expanded(child: _buildTypeCard(context, types[1])),
                const SizedBox(width: AppSizes.p12),
                Expanded(child: _buildTypeCard(context, types[2])),
                const SizedBox(width: AppSizes.p12),
                Expanded(child: _buildTypeCard(context, types[3])),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTypeCard(context, types[0])),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(child: _buildTypeCard(context, types[1])),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),
                Row(
                  children: [
                    Expanded(child: _buildTypeCard(context, types[2])),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(child: _buildTypeCard(context, types[3])),
                  ],
                ),
              ],
            );
          }
        },
      ),
      const SizedBox(height: AppSizes.p16),

      // ── Recurring toggle ──
      if (showRecurringToggle) ...[
        Row(children: [
          Checkbox(
            value: isRecurring,
            onChanged: (v) => onRecurringChanged(v ?? false),
            activeColor: AppColors.primary,
          ),
          GestureDetector(
            onTap: () => onRecurringChanged(!isRecurring),
            child: Text('Recurring booking',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ]),
        const SizedBox(height: AppSizes.p16),
      ],

      // ── Date & Time pickers ──
      Row(children: [
        Expanded(
            child: _PickerField(
                label: isRecurring ? 'Start Date' : 'Select Date',
                valueText: selectedDate != null
                    ? _fmt(selectedDate!)
                    : 'Select',
                icon: Icons.calendar_today,
                errorText: dateErrorText,
                onTap: () => _pickDate(context))),
        const SizedBox(width: AppSizes.p16),
        Expanded(
            child: _PickerField(
                label: 'Select Time',
                valueText: selectedTime != null
                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select',
                icon: Icons.access_time,
                errorText: timeErrorText,
                onTap: () => _pickTime(context))),
      ]),
    ]);
  }

  Widget _buildTypeCard(BuildContext context, AppointmentType type) {
    final bool active = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12,
              vertical: AppSizes.p16,
            ),
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 2.0 : 1.0,
              ),
              boxShadow: active ? const [AppColors.cardShadow] : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getIconForType(type),
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayLabel,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: active ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.p2),
                    Text(
                      _getSubtextForType(type),
                      style: AppTextStyles.caption.copyWith(
                        color: active ? AppColors.primary.withAlpha(200) : AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (active)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(AppointmentType type) => switch (type) {
        AppointmentType.normalPtSession => Icons.accessibility_new_rounded,
        AppointmentType.spinalTractionSession => Icons.settings_accessibility_rounded,
        AppointmentType.initialAssessment => Icons.assignment_ind_rounded,
        AppointmentType.reassessment => Icons.rate_review_rounded,
      };

  String _getSubtextForType(AppointmentType type) => switch (type) {
        AppointmentType.normalPtSession ||
        AppointmentType.spinalTractionSession =>
          'Deducts 1 Session',
        AppointmentType.initialAssessment ||
        AppointmentType.reassessment =>
          'No balance deduction',
      };

  String _fmt(DateTime d) {
    final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}';
  }

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

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) {
    final String shortId = patient.id.length > 8
        ? '${patient.id.substring(0, 6)}…${patient.id.substring(patient.id.length - 4)}'
        : patient.id;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: Row(children: [
        AppAvatar(name: patient.fullName, radius: 22),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(patient.fullName, style: AppTextStyles.bodyBold),
              const SizedBox(height: AppSizes.p2),
              Text(patient.phoneNumber, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text('ID: $shortId', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
      ]),
    );
  }
}

class _PatientSearchField extends StatelessWidget {
  const _PatientSearchField({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withAlpha(80),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: AppSizes.iconDefault),
          const SizedBox(width: AppSizes.p12),
          Text('Select Patient…', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary));
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.valueText, required this.icon, required this.onTap, this.errorText});
  final String label, valueText;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;
  @override
  Widget build(BuildContext context) {
    final bool err = errorText != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: AppSizes.p6),
      InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            border: Border.all(color: err ? AppColors.error : AppColors.border, width: AppSizes.borderWidth),
          ),
          child: Row(children: [
            Icon(icon, size: AppSizes.iconDefault, color: AppColors.textMuted),
            const SizedBox(width: AppSizes.p8),
            Expanded(child: Text(valueText, style: AppTextStyles.body.copyWith(color: valueText == 'Select' ? AppColors.textMuted : AppColors.textPrimary))),
          ]),
        ),
      ),
      if (err) ...[const SizedBox(height: AppSizes.p4), Text(errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error))],
    ]);
  }
}
