part of 'billing_detail_screen.dart';

extension _BillingDetailBody on BillingDetailScreen {
  Widget _body(
    BuildContext context,
    WidgetRef ref,
    BillingInvoice invoice,
    bool busy,
  ) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.clinicalContentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(invoice.patient.name, style: AppTextStyles.headingMedium),
              if (invoice.patient.fileNumber case final int number)
                PatientIdLabel(number),
              Text(
                '${invoice.branch.displayLabel} · ${billingPaymentState(invoice)}',
                style: AppTextStyles.bodySecondary,
              ),
              if (invoice.movements.any(
                (movement) => movement.kind == BillingDocumentKind.credit,
              ))
                Text(
                  invoice.lines.every(
                        (line) => invoice.remainingQuantity(line) == 0,
                      )
                      ? billingText.fullReturn
                      : billingText.partialReturn,
                  style: AppTextStyles.bodySecondary,
                ),
              const SizedBox(height: AppSizes.p12),
              BillingFact(billingText.doctor, invoice.doctor.name),
              if (invoice.consultant != null)
                BillingFact(billingText.consultant, invoice.consultant!.name),
              BillingFact(
                billingText.serviceDate,
                billingDate(invoice.serviceDate),
              ),
              if (invoice.issuedAt != null)
                BillingFact(
                  billingText.issuedOn,
                  billingDate(invoice.issuedAt!.toLocal()),
                ),
              const Divider(),
              for (final line in invoice.lines)
                BillingFact(
                  '${line.name} × ${line.quantity}',
                  billingAmount(line.net),
                ),
              const Divider(),
              BillingFact(
                billingText.subtotal,
                billingAmount(
                  invoice.lines.fold(
                    0,
                    (sum, line) => sum + line.unitPrice * line.quantity,
                  ),
                ),
              ),
              BillingFact(
                billingText.discount,
                '${billingDecimal(invoice.discountBps)}%',
              ),
              BillingFact(
                billingText.total,
                billingAmount(invoice.total),
                emphasis: true,
              ),
              if (!invoice.isDraft) ...[
                BillingFact(
                  billingText.collected,
                  billingAmount(invoice.collected),
                ),
                BillingFact(
                  billingText.credited,
                  billingAmount(invoice.credited),
                ),
                BillingFact(
                  billingText.refunded,
                  billingAmount(invoice.refunded),
                ),
                BillingFact(
                  billingText.outstanding,
                  billingAmount(invoice.outstanding),
                  emphasis: true,
                ),
                if (invoice.refundable > 0)
                  BillingFact(
                    billingText.refundable,
                    billingAmount(invoice.refundable),
                    emphasis: true,
                  ),
              ],
              const SizedBox(height: AppSizes.p12),
              _actions(context, ref, invoice, busy),
              if (!invoice.isDraft) ...[
                const SizedBox(height: AppSizes.p24),
                Text(billingText.movements, style: AppTextStyles.headingSmall),
                if (invoice.movements.isEmpty)
                  BillingEmpty(billingText.noMovements),
                for (final movement in invoice.movements.reversed)
                  BillingMovementTile(invoice: invoice, movement: movement),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class BillingMovementTile extends StatelessWidget {
  const BillingMovementTile({
    super.key,
    required this.invoice,
    required this.movement,
  });
  final BillingInvoice invoice;
  final BillingMovement movement;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          '${billingDocumentLabel(movement.kind)} #${movement.number} · ${billingAmount(movement.amount)}',
          style: AppTextStyles.bodyBold,
        ),
        subtitle: Text(
          [
            billingDate(movement.recordedAt.toLocal()),
            movement.actor,
            if (movement.method != null) billingMethodLabel(movement.method!),
            if (movement.reason != null) movement.reason!,
          ].join(' · '),
          style: AppTextStyles.bodySecondary,
        ),
        trailing: IconButton(
          tooltip: billingText.print,
          icon: const Icon(Icons.print_outlined),
          onPressed: () => printBillingDocument(context, invoice, movement),
        ),
      ),
    ],
  );
}
