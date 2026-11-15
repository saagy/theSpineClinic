import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/invoice_access.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/labeled_form_field.dart';
import '../../../patient/domain/patient.dart';
import 'invoice_branch_field.dart';
import 'invoice_form_input.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoices;

/// Who the invoice is for, where and when it was issued, and an optional note.
class InvoiceDetailsSection extends ConsumerWidget {
  const InvoiceDetailsSection({
    super.key,
    required this.patient,
    required this.input,
    required this.enabled,
    required this.onChanged,
  });
  final Patient patient;
  final InvoiceFormInput input;
  final bool enabled;
  final ValueChanged<VoidCallback> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    // The front desk dates invoices today; payment staff may use a past date.
    final bool canBackdate = InvoiceAccess.canManage(ref.watch(currentUserProvider).value);
    return FormSection(
      title: _t.invoiceDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(patient.fullName, style: AppTextStyles.bodyBold),
          if (patient.fileNumber != null)
            Text(
              AppStrings.patientIdLabel(patient.fileNumber!),
              style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          const SizedBox(height: AppSizes.p20),
          FormFieldPair(
            first: InvoiceBranchField(
              value: input.branch,
              enabled: enabled,
              onChanged: (branch) => onChanged(() => input.branch = branch),
            ),
            second: LabeledFormField(
              label: _t.invoiceDate,
              enabled: enabled,
              child: !canBackdate
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Tooltip(
                          message: _t.invoiceDateToday,
                          child: Text(Formatters.formatDateMedium(input.date), style: AppTextStyles.bodyMedium),
                        ),
                      ),
                    )
                  : InkWell(
                onTap: enabled ? () => _pickDate(context) : null,
                borderRadius: BorderRadius.circular(AppSizes.r6),
                child: InputDecorator(
                  decoration: appInputDecoration(
                    context,
                    enabled: enabled,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: AppSizes.iconSmall),
                  ),
                  child: Text(Formatters.formatDateMedium(input.date), style: AppTextStyles.body),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          ServiceTextInput(
            label: _t.note,
            hint: _t.noteHint,
            controller: input.note,
            enabled: enabled,
            maxLength: 500,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: input.date,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) onChanged(() => input.date = picked);
  }
}
