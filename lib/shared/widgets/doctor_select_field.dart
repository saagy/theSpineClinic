import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_select_card.dart';

/// Modern FormField for doctor selection and assignment in appointment/patient forms.
class DoctorSelectField extends FormField<List<Staff>> {
  DoctorSelectField({
    super.key,
    required List<Staff> initialValue,
    required void Function(List<Staff>)? onSavedDoctors,
    ValueChanged<List<Staff>>? onChanged,
    super.validator,
    bool enabled = true,
    bool showDeactivated = false,
  }) : super(
         initialValue: initialValue,
         onSaved: onSavedDoctors == null
             ? null
             : (val) => onSavedDoctors(val ?? []),
         builder: (FormFieldState<List<Staff>> state) {
           return _DoctorSelectFieldWidget(
             state: state,
             onChanged: onChanged,
             enabled: enabled,
             showDeactivated: showDeactivated,
           );
         },
       );
}

class _DoctorSelectFieldWidget extends StatelessWidget {
  const _DoctorSelectFieldWidget({
    required this.state,
    this.onChanged,
    required this.enabled,
    required this.showDeactivated,
  });

  final FormFieldState<List<Staff>> state;
  final ValueChanged<List<Staff>>? onChanged;
  final bool enabled;
  final bool showDeactivated;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final List<Staff> current = state.value ?? [];
    final picked = await DoctorPickerSheet.showMulti(
      context: context,
      initialSelected: current,
      showDeactivated: showDeactivated,
    );
    if (picked != null) {
      state.didChange(picked);
      onChanged?.call(picked);
      state.validate();
    }
  }

  void _removeDoctor(Staff doctor) {
    if (!enabled) return;
    final current = List<Staff>.from(state.value ?? []);
    current.removeWhere((d) => d.id == doctor.id);
    state.didChange(current);
    onChanged?.call(current);
    state.validate();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<Staff> selected = state.value ?? [];
    final bool hasError = state.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          EmptyDoctorSelectorCard(
            hasError: hasError,
            enabled: enabled,
            onTap: () => _openPicker(context),
          )
        else
          SelectedDoctorsCard(
            selected: selected,
            hasError: hasError,
            enabled: enabled,
            onAddOrChange: () => _openPicker(context),
            onRemove: _removeDoctor,
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.p4,
              top: AppSizes.p6,
            ),
            child: Text(
              state.errorText ?? '',
              style: AppTextStyles.caption.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }
}
