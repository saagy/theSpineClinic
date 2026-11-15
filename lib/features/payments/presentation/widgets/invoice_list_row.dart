import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_summary.dart';
import 'invoice_status_label.dart';

const _t = AppStrings.invoices;

bool invoiceListIsWide(BuildContext context, double width) =>
    width >= AppSizes.invoiceListWideBreakpoint && MediaQuery.textScalerOf(context).scale(1) <= 1.3;

/// One invoice: aligned money columns when wide, stacked when narrow.
class InvoiceListRow extends StatelessWidget {
  const InvoiceListRow({super.key, required this.invoice});
  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool voided = invoice.isVoided;
    final Color strong = voided ? colors.onSurfaceVariant : colors.onSurface;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final number = Text(
      invoice.displayNumber,
      style: AppTextStyles.bodyBold.copyWith(
        color: strong,
        decoration: voided ? TextDecoration.lineThrough : null,
      ),
    );
    final date = Text(Formatters.formatDateMedium(invoice.invoiceDate), style: muted);
    final services = Text(invoice.services, style: AppTextStyles.body.copyWith(color: strong));
    final doctors = invoice.doctors.isEmpty ? null : Text(invoice.doctors.join(', '), style: muted);
    final Color dueColor = invoice.dueMinor > 0 ? ClinicColors.of(context).warning : strong;
    Widget amount(int minor, {Color? color}) => Text(
      Money.format(minor),
      textAlign: TextAlign.end,
      style: AppTextStyles.number.copyWith(color: color ?? strong),
    );
    return Padding(
      padding: AppSizes.paddingCell,
      child: LayoutBuilder(
        builder: (context, box) => invoiceListIsWide(context, box.maxWidth)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSizes.invoiceNumberColumnWidth,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [number, date]),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [services, ?doctors],
                    ),
                  ),
                  SizedBox(width: AppSizes.invoiceAmountColumnWidth, child: amount(invoice.valueMinor)),
                  SizedBox(width: AppSizes.invoiceAmountColumnWidth, child: amount(invoice.collectedMinor)),
                  SizedBox(
                    width: AppSizes.invoiceAmountColumnWidth,
                    child: amount(invoice.dueMinor, color: dueColor),
                  ),
                  const SizedBox(width: AppSizes.p16),
                  SizedBox(
                    width: AppSizes.invoiceStatusColumnWidth,
                    child: InvoiceStatusLabel(invoice.displayStatus),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSizes.p8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [number, date],
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      InvoiceStatusLabel(invoice.displayStatus),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p4),
                  services,
                  ?doctors,
                  const SizedBox(height: AppSizes.p8),
                  Wrap(
                    spacing: AppSizes.p12,
                    runSpacing: AppSizes.p4,
                    children: [
                      Text(
                        _t.totalPaidLine(Money.format(invoice.valueMinor), Money.format(invoice.collectedMinor)),
                        style: muted,
                      ),
                      if (invoice.dueMinor > 0)
                        Text(
                          _t.dueLabel(Money.format(invoice.dueMinor)),
                          style: AppTextStyles.captionBold.copyWith(color: dueColor),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Column labels above wide invoice rows.
class InvoiceListHeader extends StatelessWidget {
  const InvoiceListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget amount(String label) => SizedBox(
      width: AppSizes.invoiceAmountColumnWidth,
      child: Text(label, style: style, textAlign: TextAlign.end),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      child: Row(
        children: [
          SizedBox(width: AppSizes.invoiceNumberColumnWidth, child: Text(_t.columnInvoice, style: style)),
          Expanded(child: Text(_t.columnServices, style: style)),
          amount(_t.columnTotal),
          amount(_t.paid),
          amount(_t.columnDue),
          const SizedBox(width: AppSizes.p16),
          SizedBox(width: AppSizes.invoiceStatusColumnWidth, child: Text(_t.columnStatus, style: style)),
        ],
      ),
    );
  }
}
