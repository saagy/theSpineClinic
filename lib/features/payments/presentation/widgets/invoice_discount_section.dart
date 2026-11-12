import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../domain/invoice_draft.dart';
import 'invoice_form_input.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoices;

/// Whole-invoice discount as two linked fields: typing a percentage fills in
/// the amount and typing an amount fills in the percentage. The field typed
/// in last is the one the invoice records.
class InvoiceDiscountSection extends StatefulWidget {
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
  State<InvoiceDiscountSection> createState() => _InvoiceDiscountSectionState();
}

class _InvoiceDiscountSectionState extends State<InvoiceDiscountSection> {
  @override
  void didUpdateWidget(InvoiceDiscountSection old) {
    super.didUpdateWidget(old);
    // Lines changed: refresh the mirrored field once this frame is built,
    // since changing a field's text during a build is not allowed.
    if (old.subtotalMinor == widget.subtotalMinor) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.input.syncDiscount();
    });
  }

  void _typed(DiscountKind kind) => widget.onChanged(() => widget.input.editDiscount(kind));

  @override
  Widget build(BuildContext context) {
    final InvoiceFormInput input = widget.input;
    final bool enabled = widget.enabled;
    String? check(DiscountKind kind, int max, String message) {
      if (input.discountKind != kind) return null;
      final int? value = input.discountValue;
      return value == null || value < 1 || value > max ? message : null;
    }

    return FormSection(
      title: _t.sectionDiscount,
      description: _t.freeHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldPair(
            first: ServiceTextInput(
              label: _t.discountPercentLabel,
              hint: '0',
              controller: input.discountPercent,
              enabled: enabled,
              numeric: true,
              decimal: true,
              maxLength: 6,
              onChanged: (_) => _typed(DiscountKind.percent),
              validator: (_) => check(DiscountKind.percent, 10000, _t.discountPercentInvalid),
            ),
            second: ServiceTextInput(
              label: _t.discountAmountLabel,
              hint: '0',
              controller: input.discountAmount,
              enabled: enabled,
              numeric: true,
              decimal: true,
              maxLength: 13,
              onChanged: (_) => _typed(DiscountKind.amount),
              validator: (_) => check(DiscountKind.amount, widget.subtotalMinor, _t.discountAmountInvalid),
            ),
          ),
          if (input.discountKind != DiscountKind.none) ...[
            const SizedBox(height: AppSizes.p8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: enabled ? () => widget.onChanged(input.clearDiscount) : null,
                icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                label: Text(_t.removeDiscount, style: AppTextStyles.bodyBold),
                style: TextButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
