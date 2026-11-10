part of 'billing_editor_fields.dart';

class BillingEditorTotals extends StatelessWidget {
  const BillingEditorTotals({
    super.key,
    required this.subtotal,
    required this.total,
  });
  final int subtotal;
  final int? total;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      BillingFact(billingText.subtotal, billingAmount(subtotal)),
      if (total != null)
        BillingFact(billingText.discountAmount, billingAmount(subtotal - total!)),
      BillingFact(
        billingText.total,
        total == null ? '—' : billingAmount(total!),
        emphasis: true,
      ),
    ],
  );
}

class BillingEditorFooter extends StatelessWidget {
  const BillingEditorFooter({
    super.key, required this.total, required this.busy, required this.onSave,
  });
  final int? total;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppSizes.billingTableBreakpoint;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Divider(height: AppSizes.borderWidth),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.clinicalContentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: SizedBox(width: double.infinity, child: Wrap(
                alignment: compact ? WrapAlignment.spaceBetween : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSizes.p12, runSpacing: AppSizes.p8,
                children: [
                  if (compact) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(billingText.total, style: AppTextStyles.caption),
                    Text(total == null ? '—' : billingAmount(total!), style: AppTextStyles.bodyBold),
                  ]),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, AppSizes.tappableMin)),
                    onPressed: busy ? null : onSave,
                    child: Text(busy ? billingText.saving : billingText.saveDraft, style: AppTextStyles.bodyMedium),
                  ),
                ],
              )),
            ),
          ),
        ]),
      ),
    );
  }
}

class BillingFact extends StatelessWidget {
  const BillingFact(this.label, this.value, {super.key, this.emphasis = false});
  final String label, value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label, style: AppTextStyles.body);
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: emphasis ? AppTextStyles.bodyBold : AppTextStyles.bodyMedium,
    );
    final enlarged =
        MediaQuery.textScalerOf(context).scale(1) >
        AppSizes.formPairMaxTextScale;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: enlarged
          ? Wrap(
              spacing: AppSizes.p12,
              runSpacing: AppSizes.p4,
              alignment: WrapAlignment.spaceBetween,
              children: [labelText, valueText],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: labelText),
                const SizedBox(width: AppSizes.p12),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: valueText,
                  ),
                ),
              ],
            ),
    );
  }
}

Future<List<BillingDraftLine>?> loadBillingPrices(
  WidgetRef ref,
  List<BillingDraftLine> lines,
) async {
  final result = await ref
      .read(billingRepositoryProvider)
      .items(lines.map((line) => line.item.id).toList());
  final items = result.dataOrNull;
  if (items == null || items.length != lines.length) return null;
  final byId = {for (final item in items) item.id: item};
  return [
    for (final line in lines)
      BillingDraftLine(byId[line.item.id]!, line.quantity),
  ];
}
