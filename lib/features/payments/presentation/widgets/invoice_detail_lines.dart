import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_detail.dart';

const _t = AppStrings.invoiceDetail;
const _i = AppStrings.invoices;
const _d = AppStrings.invoiceDiscount;

/// The invoice's service lines followed by the arithmetic down to the
/// amount due, in one bordered surface.
class InvoiceDetailLines extends StatelessWidget {
  const InvoiceDetailLines({super.key, required this.invoice});
  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = invoice.summary;
    final divider = Divider(
      height: AppSizes.borderWidth,
      thickness: AppSizes.borderWidth,
      color: colors.outlineVariant,
    );
    final bool reduced =
        summary.discountMinor > 0 || summary.laterDiscountMinor > 0 || summary.refundedMinor > 0;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in invoice.lines) ...[_LineRow(line), divider],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
            child: Column(
              children: [
                if (reduced) _Amount(_i.subtotal, invoice.subtotalMinor),
                if (summary.discountMinor > 0)
                  _Amount(_i.discount, -summary.discountMinor),
                if (summary.laterDiscountMinor > 0)
                  _Amount(_d.laterDiscounts, -summary.laterDiscountMinor),
                if (summary.refundedMinor > 0) _Amount(_t.refunded, -summary.refundedMinor),
                // Paid and due sit in the figures above; this is the value's arithmetic.
                _Amount(reduced ? _t.invoiceValue : _i.total, summary.valueMinor, strong: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow(this.line);
  final InvoiceLineDetail line;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final String doctors = line.doctors.isEmpty
        ? _t.noDoctors
        : line.doctors.map((doctor) => doctor.name).join(', ');
    final bool refunded = line.refundedMinor > 0 || line.sessionsCancelled > 0;
    return Padding(
      padding: AppSizes.paddingCell,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.serviceName, style: AppTextStyles.bodyBold),
                const SizedBox(height: AppSizes.p2),
                Text(
                  '${_t.quantityLine(line.quantity, Money.format(line.unitPriceMinor))} · $doctors',
                  style: muted,
                ),
                if (refunded)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p2),
                    child: Text(
                      [
                        if (line.sessionsCancelled > 0) _t.sessionsCancelled(line.sessionsCancelled),
                        if (line.refundedMinor > 0) _t.valueNow(Money.format(line.valueMinor)),
                      ].join(' · '),
                      style: muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Text(
            Money.format(line.grossMinor),
            style: AppTextStyles.number.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.minor, {this.strong = false});
  final String label;
  final int minor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: strong
                    ? AppTextStyles.bodyBold
                    : AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Text(
              minor < 0 ? '− ${Money.format(-minor)}' : Money.format(minor),
              style: AppTextStyles.number.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
