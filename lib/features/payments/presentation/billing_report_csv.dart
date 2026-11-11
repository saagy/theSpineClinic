import 'billing_report_view.dart';

/// CSV text for a report table, every column included. Starts with a byte
/// order mark so spreadsheet apps read it as UTF-8.
String billingReportCsv(ReportSheet sheet) {
  final csv = StringBuffer('﻿')..write(_line([for (final column in sheet.columns) column.label]));
  for (final row in sheet.rows) {
    csv.write(_line([for (final cell in row.cells) cell.csv]));
  }
  return csv.toString();
}

String _line(List<String> cells) => '${cells.map(_cell).join(',')}\r\n';

/// Quotes every value and disarms text a spreadsheet would run as a
/// formula. Plain negative numbers stay numbers.
String _cell(String value) {
  final bool number = RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value);
  final bool risky = RegExp(r'^\s*[=+\-@]').hasMatch(value) ||
      value.startsWith('\t') ||
      value.startsWith('\r') ||
      value.startsWith('\n');
  final String text = risky && !number ? "'$value" : value;
  return '"${text.replaceAll('"', '""')}"';
}
