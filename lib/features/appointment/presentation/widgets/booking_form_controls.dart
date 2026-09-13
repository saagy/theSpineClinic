import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';

class SegmentedAppointmentTypeSelector extends StatelessWidget {
  const SegmentedAppointmentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.enabled = true,
  });
  final AppointmentType selectedType;
  final ValueChanged<AppointmentType> onTypeChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cs = Theme.of(context).colorScheme;
      return Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          for (final type in AppointmentType.values)
            SizedBox(
              width: (constraints.maxWidth - AppSizes.p8) / 2,
              child: Semantics(
                selected: type == selectedType,
                child: OutlinedButton(
                  onPressed: enabled ? () => onTypeChanged(type) : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: type == selectedType ? cs.primaryContainer : cs.surface,
                    foregroundColor: type == selectedType ? cs.onPrimaryContainer : cs.onSurface,
                    side: BorderSide(color: type == selectedType ? cs.primary : cs.outlineVariant),
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    padding: const EdgeInsets.all(AppSizes.p12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                  ),
                  child: Text(
                    type.displayLabel,
                    textAlign: TextAlign.center,
                    style: type == selectedType ? AppTextStyles.bodyBold : AppTextStyles.body,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class BookingPickerField extends StatelessWidget {
  const BookingPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.error,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? error;
  @override
  Widget build(BuildContext context) => FormFieldLabel(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(AppSizes.inputHeight),
            side: BorderSide(
              color: error == null
                  ? Theme.of(context).colorScheme.outlineVariant
                  : Theme.of(context).colorScheme.error,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          ),
          icon: Icon(icon, size: AppSizes.iconDefault),
          label: Text(value, style: AppTextStyles.body),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p4),
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
}
