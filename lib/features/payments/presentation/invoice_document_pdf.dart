import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../domain/invoice_detail.dart';
import 'invoice_pdf_parts.dart';

const _t = AppStrings.invoiceDetail;
const _i = AppStrings.invoices;
const _d = AppStrings.invoiceDiscount;

/// A4 documents for an invoice, a receipt, a refund or a discount. Clinic details are a
/// placeholder line until the client's document template arrives.
abstract final class InvoiceDocumentPdf {
  /// Opens the system print dialog. Returns false if the document could not
  /// be prepared, so the caller can offer a retry.
  static Future<bool> print(InvoiceDetail invoice, {InvoiceReceipt? receipt, InvoiceRefund? refund}) async {
    try {
      final Uint8List bytes = await render(invoice, receipt: receipt, refund: refund);
      final String number =
          receipt?.displayNumber ?? refund?.displayNumber ?? invoice.summary.displayNumber;
      final String kind = receipt != null
          ? 'receipt'
          : refund != null
          ? refund.kind.name
          : 'invoice';
      await Printing.layoutPdf(
        name: '$kind-$number.pdf',
        format: PdfPageFormat.a4,
        onLayout: (_) => bytes,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> render(
    InvoiceDetail invoice, {
    InvoiceReceipt? receipt,
    InvoiceRefund? refund,
  }) async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'));
    final summary = invoice.summary;
    final bool voided =
        receipt?.isVoided ?? refund?.isVoided ?? invoice.isVoided;
    final document = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));
    final String patient = [
      invoice.patientName,
      if (invoice.fileNumber != null) _t.fileNumber(invoice.fileNumber!),
    ].join('\n');
    final List<pw.Widget> body;
    final PdfHeader header;
    if (receipt != null) {
      header = PdfHeader(_t.docReceipt, receipt.displayNumber, receipt.branch.displayLabel);
      body = [
        pdfFacts([
          (_t.billedTo, patient),
          (_t.forInvoice, summary.displayNumber),
          (_t.receivedAt, Formatters.formatDateTime(receipt.receivedAt)),
          (_t.recordedBy, receipt.recordedByName),
        ]),
        pdfTotals([
          (_t.method, receipt.method == PaymentMethod.cash ? _t.cash : _t.visa, false),
          (_t.amountReceived, Money.format(receipt.amountMinor), true),
          (_t.balanceAfter, Money.format(invoice.dueMinor), false),
        ]),
      ];
    } else if (refund != null) {
      final PaymentMethod? method = refund.paybackMethod;
      final bool discount = refund.isDiscount;
      header = PdfHeader(
        discount ? _d.document : _t.docRefund,
        refund.displayNumber,
        refund.branch.displayLabel,
      );
      body = [
        pdfFacts([
          (_t.billedTo, patient),
          (_t.forInvoice, summary.displayNumber),
          (_t.documentDate, Formatters.formatDateTime(refund.recordedAt)),
          (_t.recordedBy, refund.recordedByName),
        ]),
        // A discount never cancels sessions, so its table leaves them out.
        pdfTable(
          [_t.services, if (!discount) _t.columnSessions, _t.columnAmount],
          [
            for (final line in refund.lines)
              [
                invoice.lineById(line.lineId)?.serviceName ?? '',
                if (!discount) '${line.sessionsCancelled}',
                Money.format(line.valueMinor),
              ],
          ],
        ),
        pdfTotals([
          (discount ? _d.columnDiscount : _t.refundTitle, Money.format(refund.valueMinor), true),
          (
            _t.payBack,
            method == null
                ? _t.noPayback
                : _t.paidBack(Money.format(refund.paybackMinor), method == PaymentMethod.cash ? _t.cash : _t.visa),
            false,
          ),
        ]),
        pdfNote(_t.reasonLine(refund.reason)),
      ];
    } else {
      header = PdfHeader(_t.invoice, summary.displayNumber, summary.branch.displayLabel);
      body = [
        pdfFacts([
          (_t.billedTo, patient),
          (_t.invoiceDate, Formatters.formatDateMedium(summary.invoiceDate)),
          (_t.issuedBy, summary.createdByName),
        ]),
        pdfTable(
          [_t.services, _t.columnDoctors, _t.columnQty, _t.columnUnitPrice, _t.columnAmount],
          [
            for (final line in invoice.lines)
              [
                line.serviceName,
                line.doctors.map((doctor) => doctor.name).join(', '),
                '${line.quantity}',
                Money.format(line.unitPriceMinor),
                Money.format(line.grossMinor),
              ],
          ],
        ),
        pdfTotals([
          (_i.subtotal, Money.format(invoice.subtotalMinor), false),
          if (summary.discountMinor > 0) (_i.discount, '− ${Money.format(summary.discountMinor)}', false),
          if (summary.laterDiscountMinor > 0)
            (_d.laterDiscounts, '− ${Money.format(summary.laterDiscountMinor)}', false),
          if (summary.refundedMinor > 0) (_t.refunded, '− ${Money.format(summary.refundedMinor)}', false),
          (_t.invoiceValue, Money.format(summary.valueMinor), true),
          (_t.paid, Money.format(summary.collectedMinor), false),
          (_t.due, Money.format(summary.dueMinor), true),
        ]),
        if (invoice.activeReceipts.isNotEmpty)
          pdfTable(
            [_t.paymentsReceived, _t.receivedAt, _t.method, _t.columnAmount],
            [
              for (final item in invoice.activeReceipts)
                [
                  item.displayNumber,
                  Formatters.formatDateTime(item.receivedAt),
                  item.method == PaymentMethod.cash ? _t.cash : _t.visa,
                  Money.format(item.amountMinor),
                ],
            ],
          ),
        if (invoice.note != null) pdfNote(invoice.note!),
      ];
    }
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(AppSizes.p40),
          theme: pw.ThemeData.withFont(base: font, bold: font),
          buildBackground: voided ? (_) => pdfVoidMark(_t.voidWatermark) : null,
        ),
        header: (_) => header.build(AppStrings.appName, _t.clinicDetails),
        footer: (page) => pdfFooter(_t.page(page.pageNumber, page.pagesCount)),
        build: (_) => body,
      ),
    );
    return document.save();
  }
}
