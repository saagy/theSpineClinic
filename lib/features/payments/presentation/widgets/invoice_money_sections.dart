import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../domain/invoice_draft.dart';
import 'invoice_form_input.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoices;

/// Whole-invoice discount as a percentage or a fixed amount.
class InvoiceDiscountSection extends StatelessWidget {
  const InvoiceDiscountSection({
    super.key,
    required this.input,
    required this.subtotalMinor,
    required this.enabled,
    required this.onChanged,
  });
  final InvoiceFormInput input;
  final int subtotalMinor;
  final bool enabled;
  final ValueChanged<VoidCallback> onChanged;

  @override
  Widget build(BuildContext context) => FormSection(
    title: _t.sectionDiscount,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DiscountKind>(
          segments: [
            ButtonSegment(value: DiscountKind.none, label: Text(_t.discountNone)),
            ButtonSegment(value: DiscountKind.percent, label: Text(_t.discountPercent)),
            ButtonSegment(value: DiscountKind.amount, label: Text(_t.discountAmount)),
          ],
          selected: {input.discountKind},
          showSelectedIcon: false,
          style: const ButtonStyle(
            textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
            minimumSize: WidgetStatePropertyAll(Size(AppSizes.tappableMin, AppSizes.tappableMin)),
          ),
          onSelectionChanged: enabled
              ? (kinds) => onChanged(() {
                  input.discountKind = kinds.first;
                  input.discount.clear();
                })
              : null,
        ),
        if (input.discountKind != DiscountKind.none) ...[
          const SizedBox(height: AppSizes.p20),
          ServiceTextInput(
            key: ValueKey(input.discountKind),
            label: input.discountKind == DiscountKind.percent ? _t.discountPercentLabel : _t.discountAmountLabel,
            controller: input.discount,
            enabled: enabled,
            numeric: true,
            decimal: true,
            maxLength: 13,
            validator: (_) {
              final int? value = input.discountValue;
              if (input.discountKind == DiscountKind.percent) {
                return value == null || value < 1 || value > 10000 ? _t.discountPercentInvalid : null;
              }
              return value == null || value < 1 || value > subtotalMinor ? _t.discountAmountInvalid : null;
            },
          ),
          if (input.discountKind == DiscountKind.percent) ServiceFieldNote(_t.freeHint),
        ],
      ],
    ),
  );
}

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
