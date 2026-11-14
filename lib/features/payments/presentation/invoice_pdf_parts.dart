import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/app_sizes.dart';

// Print sizes in points; screen tokens do not apply to paper.
const double _small = 8;
const double _text = 10;
const double _title = 20;
const PdfColor _ink = PdfColors.grey900;
const PdfColor _muted = PdfColors.grey600;
const PdfColor _rule = PdfColors.grey300;

pw.TextStyle _style(double size, [PdfColor color = _ink]) =>
    pw.TextStyle(fontSize: size, color: color);

/// Clinic identity on the left; document kind, number and branch on the right.
class PdfHeader {
  const PdfHeader(this.kind, this.number, this.branch);
  final String kind;
  final String number;
  final String branch;

  pw.Widget build(String clinic, String clinicDetails) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: AppSizes.p16),
    margin: const pw.EdgeInsets.only(bottom: AppSizes.p20),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _rule)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(clinic, style: _style(AppSizes.p16)),
              pw.SizedBox(height: AppSizes.p4),
              pw.Text(branch, style: _style(_text, _muted)),
              pw.Text(clinicDetails, style: _style(_small, _muted)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(kind.toUpperCase(), style: _style(_title).copyWith(letterSpacing: 1)),
            pw.SizedBox(height: AppSizes.p4),
            pw.Text(number, style: _style(AppSizes.p12, _muted)),
          ],
        ),
      ],
    ),
  );
}

/// Labeled facts in a row, such as who the document is for and when.
/// Labeled values in one row; [notes] adds a small line under a value.
pw.Widget pdfFacts(List<(String, String)> facts, {List<String?> notes = const []}) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: AppSizes.p20),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final (int index, (String label, String value)) in facts.indexed)
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label.toUpperCase(), style: _style(_small, _muted)),
              pw.SizedBox(height: AppSizes.p4),
              pw.Text(value, style: _style(_text)),
              if (index < notes.length && notes[index] != null)
                pw.Text(notes[index]!, style: _style(_small, _muted)),
            ],
          ),
        ),
    ],
  ),
);

/// A ruled table. By default the first column takes the spare width and the
/// last column aligns right; reports name their [wide] and [numeric] columns.
pw.Widget pdfTable(
  List<String> headers,
  List<List<String>> rows, {
  Set<int>? numeric,
  Set<int>? wide,
}) {
  final int last = headers.length - 1;
  final Set<int> right = numeric ?? {last};
  final Set<int> roomy = wide ?? {0};
  // A line break starts a quieter second line, such as an ID under a name.
  pw.Widget cell(String text, int column, {bool head = false}) {
    final pw.TextAlign align = right.contains(column) ? pw.TextAlign.right : pw.TextAlign.left;
    final int split = head ? -1 : text.indexOf('\n');
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: AppSizes.p6, horizontal: AppSizes.p4),
      child: split < 0
          ? pw.Text(
              head ? text.toUpperCase() : text,
              textAlign: align,
              style: head ? _style(_small, _muted) : _style(_text),
            )
          : pw.Column(
              crossAxisAlignment: right.contains(column)
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(text.substring(0, split), textAlign: align, style: _style(_text)),
                pw.Text(text.substring(split + 1), textAlign: align, style: _style(_small, _muted)),
              ],
            ),
    );
  }

  const rule = pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: AppSizes.p16),
    child: pw.Table(
      columnWidths: {
        for (int column = 0; column <= last; column++)
          column: pw.FlexColumnWidth(roomy.contains(column) ? 3 : 1.4),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: rule,
          children: [for (final (index, text) in headers.indexed) cell(text, index, head: true)],
        ),
        for (final row in rows)
          pw.TableRow(
            decoration: rule,
            children: [for (final (index, text) in row.indexed) cell(text, index)],
          ),
      ],
    ),
  );
}

/// Right-aligned totals; strong rows are the figures a reader looks for.
pw.Widget pdfTotals(List<(String, String, bool)> rows) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: AppSizes.p20),
  child: pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 240,
      child: pw.Column(
        children: [
          for (final (String label, String value, bool strong) in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: AppSizes.p4,
                horizontal: AppSizes.p4,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      label,
                      style: _style(strong ? AppSizes.p12 : _text, strong ? _ink : _muted),
                    ),
                  ),
                  pw.SizedBox(width: AppSizes.p12),
                  pw.Text(
                    value,
                    textAlign: pw.TextAlign.right,
                    style: _style(strong ? AppSizes.p12 : _text),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  ),
);

/// A section title above a table.
pw.Widget pdfHeading(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: AppSizes.p8),
  child: pw.Text(text, style: _style(AppSizes.p12)),
);

pw.Widget pdfNote(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: AppSizes.p16),
  child: pw.Text(text, style: _style(_text, _muted)),
);

pw.Widget pdfFooter(String page) => pw.Container(
  margin: const pw.EdgeInsets.only(top: AppSizes.p16),
  alignment: pw.Alignment.centerRight,
  child: pw.Text(page, style: _style(_small, _muted)),
);

/// Large diagonal mark behind a voided document's content.
pw.Widget pdfVoidMark(String text) => pw.FullPage(
  ignoreMargins: true,
  child: pw.Center(
    child: pw.Transform.rotate(
      angle: math.pi / 5,
      child: pw.Text(text, style: _style(120, PdfColors.grey200).copyWith(letterSpacing: 8)),
    ),
  ),
);
