import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
import '../../../core/constants/app_sizes.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import 'billing_ui.dart';

Future<void> printBillingDocument(
  BuildContext context,
  BillingInvoice invoice, [
  BillingMovement? movement,
]) async {
  final kind = movement?.kind ?? BillingDocumentKind.invoice;
  final number = movement?.number ?? invoice.number;
  try {
    final bytes = await renderBillingDocument(invoice, movement);
    await Printing.layoutPdf(
      name: '${invoice.branch.dbValue}-${kind.name}-$number.pdf',
      format: PdfPageFormat.a4,
      onLayout: (_) => bytes,
    );
  } catch (_) {
    if (context.mounted) billingMessage(context, billingText.printRetry);
  }
}

Future<Uint8List> renderBillingDocument(
  BillingInvoice invoice,
  BillingMovement? movement,
) async {
  final latin = pdf.Font.ttf(
    await rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
  );
  final document = pdf.Document(
    theme: pdf.ThemeData.withFont(base: latin, bold: latin),
  );
  final kind = movement?.kind ?? BillingDocumentKind.invoice;
  final label = billingDocumentLabel(kind);
  final number = movement?.number ?? invoice.number;
  final lineById = {for (final line in invoice.lines) line.id: line};
  final allocations = movement?.allocations ?? const <BillingAllocation>[];
  document.addPage(
    pdf.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pdf.EdgeInsets.all(AppSizes.p32),
      build: (_) => [
        pdf.Text(
          '$label #$number',
          style: pdf.TextStyle(
            fontSize: AppSizes.p24,
            fontWeight: pdf.FontWeight.bold,
          ),
        ),
        pdf.Text(invoice.branch.displayLabel),
        pdf.SizedBox(height: AppSizes.p12),
        _fact(billingText.patient, invoice.patient.name),
        _fact(billingText.file, invoice.patient.fileNumber.toString()),
        _fact(billingText.doctor, invoice.doctor.name),
        if (invoice.consultant != null)
          _fact(billingText.consultant, invoice.consultant!.name),
        _fact(billingText.serviceDate, billingDate(invoice.serviceDate)),
        if (movement == null && invoice.issuedAt != null)
          _fact(billingText.issuedOn, billingDate(invoice.issuedAt!.toLocal())),
        if (movement != null) ...[
          _fact(billingText.invoiceReference, '#${invoice.number}'),
          _fact(
            billingText.recordedAt,
            billingDate(movement.recordedAt.toLocal()),
          ),
          _fact(billingText.recordedBy, movement.actor),
          if (movement.method != null)
            _fact(billingText.method, billingMethodLabel(movement.method!)),
          if (movement.reason != null)
            _fact(billingText.reason, movement.reason!),
        ],
        pdf.SizedBox(height: AppSizes.p12),
        if (movement == null)
          _table(
            [
              billingText.service,
              billingText.quantity,
              billingText.unitPrice,
              billingText.lineTotal,
            ],
            [
              for (final line in invoice.lines)
                [
                  line.name,
                  line.quantity.toString(),
                  billingAmount(line.unitPrice),
                  billingAmount(line.net),
                ],
            ],
          ),
        if (allocations.isNotEmpty)
          _table(
            [
              billingText.service,
              if (kind == BillingDocumentKind.credit)
                billingText.returnedQuantity,
              billingText.amount,
            ],
            [
              for (final part in allocations)
                [
                  lineById[part.lineId]!.name,
                  if (kind == BillingDocumentKind.credit)
                    part.quantity.toString(),
                  billingAmount(part.amount),
                ],
            ],
          ),
        pdf.SizedBox(height: AppSizes.p12),
        if (movement == null) ...[
          _fact(
            billingText.subtotal,
            billingAmount(
              invoice.lines.fold(
                0,
                (sum, line) => sum + line.unitPrice * line.quantity,
              ),
            ),
          ),
          _fact(
            billingText.discount,
            '${billingDecimal(invoice.discountBps)}%',
          ),
        ],
        if (kind == BillingDocumentKind.credit && movement != null)
          _fact(billingText.debtReduced, billingAmount(movement.debtReduced)),
        _fact(
          movement == null ? billingText.total : billingText.amount,
          billingAmount(movement?.amount ?? invoice.total),
        ),
      ],
      footer: (page) => pdf.Align(
        alignment: pdf.Alignment.centerRight,
        child: pdf.Text(
          '${billingText.page} ${page.pageNumber} / ${page.pagesCount}',
        ),
      ),
    ),
  );
  return document.save();
}

pdf.Widget _fact(String label, String value) => pdf.Padding(
  padding: const pdf.EdgeInsets.symmetric(vertical: AppSizes.p4),
  child: pdf.Row(
    crossAxisAlignment: pdf.CrossAxisAlignment.start,
    children: [
      pdf.Expanded(child: pdf.Text(label)),
      pdf.Expanded(child: pdf.Text(value)),
    ],
  ),
);

pdf.Table _table(List<String> headers, List<List<String>> rows) => pdf.Table(
  columnWidths: {0: const pdf.FlexColumnWidth(2)},
  children: [
    pdf.TableRow(repeat: true, children: headers.map(_cell).toList()),
    for (final row in rows) pdf.TableRow(children: row.map(_cell).toList()),
  ],
);

pdf.Widget _cell(String text) => pdf.Padding(
  padding: const pdf.EdgeInsets.all(AppSizes.p8),
  child: pdf.Text(text),
);
