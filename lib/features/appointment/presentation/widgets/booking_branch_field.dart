import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/record_menu_select.dart';

const _s = AppStrings.staffSchedule;

/// Where a visit happens. Notes when the patient is registered elsewhere,
/// so nobody books the wrong branch by accident; it never blocks.
class BookingBranchField extends StatelessWidget {
  const BookingBranchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.registeredAt,
    this.lockedMessage,
  });

  final ClinicLocation? value;
  final ClinicLocation? registeredAt;

  /// Null when the branch cannot be changed.
  final ValueChanged<ClinicLocation>? onChanged;

  /// Why the branch is locked, shown under the field.
  final String? lockedMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String? note = lockedMessage ??
        (registeredAt != null && value != null && registeredAt != value
            ? _s.registeredAt(registeredAt!.displayLabel)
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormField(
          label: _s.visitBranch,
          enabled: onChanged != null,
          child: RecordMenuSelect<ClinicLocation?>(
            label: AppStrings.selectBranch,
            value: value,
            isField: true,
            decoration: appInputDecoration(context, enabled: onChanged != null),
            options: [
              for (final branch in ClinicLocation.values)
                RecordMenuAction(branch, branch.displayLabel, Icons.location_on_outlined, selected: branch == value),
            ],
            onChanged: onChanged == null ? null : (branch) => branch == null ? null : onChanged!(branch),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSizes.p6),
          Text(note, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
        ],
      ],
    );
  }
}
