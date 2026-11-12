import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/labeled_form_field.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_detail.dart';
import 'invoice_line_editor.dart';
import 'invoice_timeline.dart';
import 'refund_form_input.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoiceDetail;

/// Each refundable line with the sessions to cancel and the agreed value.
class RefundLinesSection extends StatelessWidget {
  const RefundLinesSection({
    super.key,
    required this.input,
    required this.enabled,
    required this.showMissing,
    required this.onChanged,
  });
  final RefundFormInput input;
  final bool enabled;
  final bool showMissing;
  final ValueChanged<VoidCallback> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    return FormSection(
      title: _t.refundLines,
      description: _t.refundHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, line) in input.lines.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                child: Divider(height: AppSizes.borderWidth, color: colors.outlineVariant),
              ),
            Text(line.line.serviceName, style: AppTextStyles.bodyBold),
            Text(_t.lineValue(Money.format(line.line.valueMinor)), style: muted),
            const SizedBox(height: AppSizes.p12),
            FormFieldPair(
              first: ServiceTextInput(
                label: _t.refundValue,
                hint: '0',
                controller: line.value,
                enabled: enabled && line.line.valueMinor > 0,
                numeric: true,
                decimal: true,
                maxLength: 13,
                validator: (_) {
                  final int? value = line.valueMinor;
                  if (value == null) return AppStrings.invoices.amountInvalid;
                  return value > line.line.valueMinor
                      ? _t.valueTooHigh(Money.format(line.line.valueMinor))
                      : null;
                },
              ),
              second: line.line.type.usesSessions ? _sessions(line, muted) : null,
            ),
          ],
          if (showMissing && !input.draft().hasLines)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.p12),
              child: Text(_t.refundEmpty, style: AppTextStyles.caption.copyWith(color: colors.error)),
            ),
        ],
      ),
    );
  }

  Widget _sessions(RefundLineInput line, TextStyle muted) {
    final int limit = input.sessionLimit(line);
    return LabeledFormField(
      label: _t.sessionsToCancel,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuantityStepper(
            value: line.sessions,
            min: 0,
            max: limit,
            label: _t.sessionsToCancel,
            decreaseTooltip: _t.decreaseSessions,
            increaseTooltip: _t.increaseSessions,
            onChanged: enabled ? (value) => onChanged(() => line.sessions = value) : null,
          ),
          const SizedBox(height: AppSizes.p4),
          Text(limit == 0 ? _t.noSessionsAvailable : _t.sessionsAvailable(limit), style: muted),
        ],
      ),
    );
  }
}

/// Where the refund is recorded, how any money goes back, and why.
class RefundDetailsSection extends StatelessWidget {
  const RefundDetailsSection({
    super.key,
    required this.input,
    required this.paybackMinor,
    required this.enabled,
    required this.showMissing,
    required this.onChanged,
  });
  final RefundFormInput input;
  final int paybackMinor;
  final bool enabled;
  final bool showMissing;
  final ValueChanged<VoidCallback> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final PaymentMethod? method = input.method;
    return FormSection(
      title: _t.refundDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paybackMinor > 0) ...[
            LabeledFormField(
              label: '${_t.paybackMethod} · ${Money.format(paybackMinor)}',
              enabled: enabled,
              child: SegmentedButton<PaymentMethod>(
                segments: [
                  for (final option in PaymentMethod.values)
                    ButtonSegment(value: option, label: Text(paymentMethodLabel(option))),
                ],
                selected: {?method},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                style: const ButtonStyle(
                  textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
                  minimumSize: WidgetStatePropertyAll(Size(AppSizes.tappableMin, AppSizes.tappableMin)),
                ),
                onSelectionChanged: enabled
                    ? (methods) => onChanged(() => input.method = methods.firstOrNull ?? method)
                    : null,
              ),
            ),
            if (showMissing && method == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.p6),
                child: Text(
                  _t.paybackMethodRequired,
                  style: AppTextStyles.caption.copyWith(color: colors.error),
                ),
              ),
          ] else
            Text(_t.paybackNone, style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSizes.p20),
          LabeledFormField(
            label: _t.branch,
            enabled: enabled,
            child: RecordMenuSelect<ClinicLocation>(
              label: _t.branch,
              value: input.branch,
              isField: true,
              decoration: appInputDecoration(context, enabled: enabled),
              options: [
                for (final branch in ClinicLocation.values)
                  RecordMenuAction(branch, branch.displayLabel, Icons.location_on_outlined),
              ],
              onChanged: enabled ? (branch) => onChanged(() => input.branch = branch) : null,
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          ServiceTextInput(
            label: _t.reason,
            hint: _t.refundReasonHint,
            controller: input.reason,
            enabled: enabled,
            maxLength: 500,
            validator: (text) => text.isEmpty ? _t.reasonRequired : null,
          ),
        ],
      ),
    );
  }
}
