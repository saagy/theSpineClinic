import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import 'invoice_form_input.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoices;

/// Money received together with the invoice, by cash, Visa or both.
class InvoicePaymentSection extends StatelessWidget {
  const InvoicePaymentSection({
    super.key,
    required this.input,
    required this.totalMinor,
    required this.enabled,
    required this.onChanged,
  });
  final InvoiceFormInput input;
  final int totalMinor;
  final bool enabled;
  final ValueChanged<VoidCallback> onChanged;

  @override
  Widget build(BuildContext context) {
    final int? cash = input.cashMinor;
    final int? visa = input.visaMinor;
    final bool tooHigh = cash != null && visa != null && cash + visa > totalMinor;
    String? validate(int? value) =>
        value == null ? _t.amountInvalid : tooHigh ? _t.paymentTooHigh : null;
    return FormSection(
      title: _t.sectionPayment,
      description: _t.paymentHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldPair(
            first: ServiceTextInput(
              label: _t.cash,
              hint: '0',
              controller: input.cash,
              enabled: enabled,
              numeric: true,
              decimal: true,
              maxLength: 13,
              validator: (_) => validate(input.cashMinor),
            ),
            second: ServiceTextInput(
              label: _t.visa,
              hint: '0',
              controller: input.visa,
              enabled: enabled,
              numeric: true,
              decimal: true,
              maxLength: 13,
              validator: (_) => validate(input.visaMinor),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: enabled && totalMinor > 0
                  ? () => onChanged(() {
                      input.cash.text = Money.editable(totalMinor);
                      input.visa.clear();
                    })
                  : null,
              icon: const Icon(Icons.payments_outlined, size: AppSizes.iconSmall),
              label: Text(_t.payInFull, style: AppTextStyles.bodyBold),
              style: TextButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
            ),
          ),
        ],
      ),
    );
  }
}
