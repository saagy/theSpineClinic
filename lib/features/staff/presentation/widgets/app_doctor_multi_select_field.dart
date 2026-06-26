import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_search_sheet.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/selected_doctor_row.dart';

/// Reusable searchable custom form field for doctor multi-selection.
///
/// Tapping the search field opens a [DoctorSearchSheet] bottom sheet with a
/// searchable doctor list. Selected doctors display as avatar+name rows with
/// a remove action. Enforces a minimum of one selected doctor.
class AppDoctorMultiSelectField extends FormField<List<Staff>> {
  AppDoctorMultiSelectField({
    super.key,
    required List<Staff> initialValue,
    required void Function(List<Staff>)? onSavedDoctors,
    ValueChanged<List<Staff>>? onChanged,
    super.validator,
    bool enabled = true,
  }) : super(
          initialValue: initialValue,
          onSaved: onSavedDoctors == null
              ? null
              : (val) => onSavedDoctors(val ?? []),
          builder: (FormFieldState<List<Staff>> state) {
            return _AppDoctorMultiSelectFieldWidget(
              state: state,
              onChanged: onChanged,
              enabled: enabled,
            );
          },
        );
}

class _AppDoctorMultiSelectFieldWidget extends ConsumerStatefulWidget {
  const _AppDoctorMultiSelectFieldWidget({
    required this.state,
    this.onChanged,
    required this.enabled,
  });
  final FormFieldState<List<Staff>> state;
  final ValueChanged<List<Staff>>? onChanged;
  final bool enabled;

  @override
  ConsumerState<_AppDoctorMultiSelectFieldWidget> createState() =>
      _AppDoctorMultiSelectFieldWidgetState();
}

class _AppDoctorMultiSelectFieldWidgetState
    extends ConsumerState<_AppDoctorMultiSelectFieldWidget> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDoctorSheet(List<Staff> activeDoctors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DoctorSearchSheet(
        activeDoctors: activeDoctors,
        selectedDoctors: widget.state.value ?? [],
        onSelectionChanged: (updated) {
          widget.state.didChange(updated);
          widget.onChanged?.call(updated);
          widget.state.validate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.state.value ?? [];
    final doctorsAsync = ref.watch(activeDoctorsProvider);
    final bool hasData = doctorsAsync.hasValue;
    final bool isLoading = doctorsAsync.isLoading;
    final bool hasError = doctorsAsync.hasError;

    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      borderSide: BorderSide(
        color: widget.state.hasError ? AppColors.error : AppColors.border,
        width: AppSizes.borderWidth,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          readOnly: true,
          enabled: widget.enabled && (hasData || hasError),
          onTap: () {
            if (!widget.enabled || !hasData) return;
            _openDoctorSheet(doctorsAsync.value!);
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            labelText: AppStrings.searchAndAssignDoctors,
            hintText: AppStrings.typeDoctorName,
            suffixIcon: isLoading
                ? const SizedBox(
                    width: AppSizes.iconDefault,
                    height: AppSizes.iconDefault,
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.p8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : hasError
                    ? GestureDetector(
                        onTap: () =>
                            ref.invalidate(activeDoctorsProvider),
                        child: const Icon(Icons.refresh_rounded,
                            color: AppColors.error,
                            size: AppSizes.iconDefault),
                      )
                    : const Icon(Icons.search_rounded),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.borderStrong,
                width: AppSizes.borderWidthFocused,
              ),
            ),
            disabledBorder: border,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p6),
            child: Text(
              AppStrings.unableToLoadDoctors,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSizes.p12),
          Column(
            children: selected.map((doc) => SelectedDoctorRow(
              doctor: doc,
              showRemove: widget.enabled,
              onRemove: () {
                final updated = selected.where((d) => d.id != doc.id).toList();
                widget.state.didChange(updated);
                widget.onChanged?.call(updated);
                widget.state.validate();
              },
            )).toList(),
          ),
        ],
        if (widget.state.hasError) ...[
          const SizedBox(height: AppSizes.p6),
          Text(
            widget.state.errorText ?? '',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
