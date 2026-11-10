import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/patient_id_label.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import 'billing_ui.dart';

class BillingRegisterTable extends StatelessWidget {
  const BillingRegisterTable({
    super.key,
    required this.invoices,
    required this.onOpen,
  });
  final List<BillingInvoice> invoices;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [BillingEmpty(billingText.noInvoices)],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppSizes.billingTableBreakpoint &&
            MediaQuery.textScalerOf(context).scale(1) <=
                AppSizes.formPairMaxTextScale;
        return Column(
          children: [
            if (wide)
              _wideRow([
                billingText.invoice,
                billingText.patient,
                billingText.doctor,
                billingText.serviceDate,
                billingText.total,
                billingText.collected,
                billingText.outstanding,
              ], header: true),
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: invoices.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: AppSizes.borderWidth),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final reference = invoice.number == null
                      ? billingText.draft
                      : '#${invoice.number}';
                  final date = billingDate(invoice.serviceDate);
                  return InkWell(
                    onTap: () => onOpen(invoice.id),
                    child: wide
                        ? _wideRow([
                            '$reference\n${invoice.branch.displayLabel}',
                            invoice.patient.name,
                            invoice.doctor.name,
                            date,
                            billingAmount(invoice.total),
                            billingAmount(invoice.collected),
                            invoice.isDraft
                                ? billingText.draft
                                : billingAmount(invoice.outstanding),
                          ], patient: invoice.patient)
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.p12,
                              horizontal: AppSizes.p8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.patient.name,
                                  style: AppTextStyles.bodyBold,
                                ),
                                if (invoice.patient.fileNumber
                                    case final int number)
                                  PatientIdLabel(number),
                                Text(
                                  '$reference · ${invoice.branch.displayLabel} · $date',
                                  style: AppTextStyles.body,
                                ),
                                Text(
                                  invoice.doctor.name,
                                  style: AppTextStyles.bodySecondary,
                                ),
                                const SizedBox(height: AppSizes.p4),
                                Wrap(
                                  spacing: AppSizes.p12,
                                  runSpacing: AppSizes.p4,
                                  children: [
                                    Text(
                                      '${billingText.total} ${billingAmount(invoice.total)}',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      invoice.isDraft
                                          ? billingText.draft
                                          : '${billingText.outstanding} ${billingAmount(invoice.outstanding)}',
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _wideRow(
    List<String> cells, {
    bool header = false,
    BillingParty? patient,
  }) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: AppSizes.p12,
      horizontal: AppSizes.p8,
    ),
    child: Row(
      children: [
        for (int index = 0; index < cells.length; index++)
          Expanded(
            flex: index == 1 || index == 2 ? 2 : 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.p8),
              child: index == 1 && patient?.fileNumber != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cells[index], style: AppTextStyles.body),
                        PatientIdLabel(patient!.fileNumber!),
                      ],
                    )
                  : Text(
                      cells[index],
                      textAlign: index >= 4 ? TextAlign.end : TextAlign.start,
                      style: header
                          ? AppTextStyles.bodyBold
                          : AppTextStyles.body,
                    ),
            ),
          ),
      ],
    ),
  );
}
