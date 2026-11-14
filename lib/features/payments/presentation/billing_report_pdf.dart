import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import 'billing_report_view.dart';
import 'invoice_pdf_parts.dart';

const _t = AppStrings.billingReports;

/// A4 landscape print of a report: totals, then each table as shown on
/// screen.
abstract final class BillingReportPdf {
  /// Opens the system print dialog. Returns false if the document could not
  /// be prepared.
  static Future<bool> print({
    required String title,
    required String period,
    required String scope,
    required ReportView view,
    required String fileName,
  }) async {
    try {
      final Uint8List bytes = await render(title: title, period: period, scope: scope, view: view);
      await Printing.layoutPdf(
        name: '$fileName.pdf',
        format: PdfPageFormat.a4.landscape,
        onLayout: (_) => bytes,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> render({
    required String title,
    required String period,
    required String scope,
    required ReportView view,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
    );
    final theme = pw.ThemeData.withFont(base: font, bold: font);
    final document = pw.Document(theme: theme);
    final header = PdfHeader(title, period, scope);
    final String printed = _t.printedAt(Formatters.formatDateTime(DateTime.now()));
    document.addPage(
      pw.MultiPage(
        maxPages: 400,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(AppSizes.p32),
          theme: theme,
        ),
        header: (_) => header.build(AppStrings.appName, AppStrings.invoiceDetail.clinicDetails),
        footer: (page) => pdfFooter(
          '$printed · ${AppStrings.invoiceDetail.page(page.pageNumber, page.pagesCount)}',
        ),
        build: (_) => [
          pdfFacts(
            [for (final figure in view.figures) (figure.label, figure.value)],
            notes: [for (final figure in view.figures) figure.caption],
          ),
          for (final section in view.sections)
            if (section.sheet.rows.isNotEmpty || section.emptyMessage != null) ...[
              if (section.newPage) pw.NewPage(),
              if (section.title != null) pdfHeading(section.title!),
              if (section.note != null) pdfNote(section.note!),
              if (section.sheet.rows.isEmpty)
                pdfNote(section.emptyMessage!)
              else
                _table(section.sheet),
            ],
        ],
      ),
    );
    return document.save();
  }

  /// One cell; a line break before the second line marks it as quieter, so
  /// typed text (such as a reason) is kept to one line.
  static String _printed(ReportCell cell) {
    String flat(String text) => text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
    return cell.sub == null ? flat(cell.text) : '${flat(cell.text)}\n${flat(cell.sub!)}';
  }

  static pw.Widget _table(ReportSheet sheet) {
    final shown = [for (var index = 0; index < sheet.columns.length; index++) index];
    List<String> pick(List<ReportCell> cells) => [
      for (final index in shown) _printed(cells[index]),
    ];
    return pdfTable(
      [for (final index in shown) sheet.columns[index].label],
      [
        for (final row in sheet.rows) pick(row.cells),
        if (sheet.footer != null) pick(sheet.footer!),
      ],
      numeric: {
        for (final (position, index) in shown.indexed)
          if (sheet.columns[index].numeric) position,
      },
      wide: {
        for (final (position, index) in shown.indexed)
          if (sheet.columns[index].width == null) position,
      },
    );
  }
}
