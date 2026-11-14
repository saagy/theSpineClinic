import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/labeled_form_field.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_access.dart';

const _t = AppStrings.invoices;

/// The branch a billing document belongs to. Receptionists work at one
/// branch, so they see it as plain text; staff without a fixed branch choose.
class InvoiceBranchField extends ConsumerWidget {
  const InvoiceBranchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final ClinicLocation value;
  final ValueChanged<ClinicLocation> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool fixed = InvoiceAccess.fixedBranch(ref.watch(currentUserProvider).value) != null;
    return LabeledFormField(
      label: _t.branch,
      enabled: enabled,
      child: fixed
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(value.displayLabel, style: AppTextStyles.bodyMedium),
              ),
            )
          : RecordMenuSelect<ClinicLocation>(
              label: _t.branch,
              value: value,
              isField: true,
              decoration: appInputDecoration(context, enabled: enabled),
              options: [
                for (final branch in ClinicLocation.values)
                  RecordMenuAction(branch, branch.displayLabel, Icons.location_on_outlined),
              ],
              onChanged: enabled ? onChanged : null,
            ),
    );
  }
}
