import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/record_action_menu.dart';
import '../../../shared/widgets/record_menu_select.dart';
import '../../../shared/widgets/patient_id_label.dart';
import '../../patient/domain/clinic_location.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_editor_totals.dart';

class BillingPartyField extends StatelessWidget {
  const BillingPartyField({
    super.key,
    required this.label,
    required this.party,
    required this.action,
    required this.onTap,
    this.onClear,
  });
  final String label, action;
  final BillingParty? party;
  final VoidCallback? onTap, onClear;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: AppTextStyles.bodyBold),
    isThreeLine: party?.fileNumber != null,
    subtitle: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(party?.name ?? action, style: AppTextStyles.body),
        if (party?.fileNumber case final int number) PatientIdLabel(number),
      ],
    ),
    trailing: onClear == null
        ? const Icon(Icons.chevron_right)
        : IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
    onTap: onTap,
  );
}

class BillingBranchField extends StatelessWidget {
  const BillingBranchField({
    super.key,
    required this.branch,
    required this.onChanged,
  });
  final ClinicLocation? branch;
  final ValueChanged<ClinicLocation?>? onChanged;
  @override
  Widget build(BuildContext context) => RecordMenuSelect<ClinicLocation?>(
    label: billingText.branch,
    value: branch,
    isField: true,
    options: [
      for (final item in ClinicLocation.values)
        RecordMenuAction(item, item.displayLabel, Icons.location_on_outlined),
    ],
    onChanged: onChanged,
  );
}

class BillingEditorLines extends StatelessWidget {
  const BillingEditorLines({
    super.key,
    required this.lines,
    required this.busy,
    required this.onAdd,
    required this.onRefresh,
    required this.onRemove,
    required this.onQuantity,
  });
  final List<BillingDraftLine> lines;
  final bool busy;
  final VoidCallback onAdd, onRefresh;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onQuantity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(billingText.services, style: AppTextStyles.headingSmall),
      if (lines.isEmpty) BillingEmpty(billingText.noServices),
      for (final (index, line) in lines.indexed) ...[
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.item.name, style: AppTextStyles.bodyBold),
                  Text(
                    billingAmount(line.item.price),
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: AppSizes.billingQuantityWidth,
              child: TextFormField(
                key: ValueKey(line.item.id),
                initialValue: line.quantity.toString(),
                enabled: !busy,
                style: AppTextStyles.body,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: billingText.quantity),
                validator: (text) {
                  final value = int.tryParse(text ?? '');
                  return value == null || value < 1 || value > 1000
                      ? billingText.quantityError
                      : null;
                },
                onChanged: (text) {
                  final value = int.tryParse(text);
                  if (value != null && value >= 1 && value <= 1000) {
                    onQuantity(index, value);
                  }
                },
              ),
            ),
            IconButton(
              tooltip: billingText.remove,
              onPressed: busy ? null : () => onRemove(index),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
      const SizedBox(height: AppSizes.p12),
      Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          OutlinedButton.icon(
            onPressed: busy || lines.length >= 100 ? null : onAdd,
            icon: const Icon(Icons.add),
            label: Text(billingText.addService),
          ),
          if (lines.isNotEmpty)
            TextButton(
              onPressed: busy ? null : onRefresh,
              child: Text(billingText.refreshPrices),
            ),
        ],
      ),
    ],
  );
}
