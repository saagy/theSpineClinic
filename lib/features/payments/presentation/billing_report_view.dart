import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../domain/billing_report.dart';

/// How a cell is placed when a table has no room for columns: the title
/// leads the row, the lead amount sits opposite it, meta values share a
/// line, and figures follow with their column labels.
enum ReportCellRole { title, meta, figure, lead }

enum ReportTone { normal, muted, warning }

class ReportColumn {
  const ReportColumn(
    this.label, {
    this.width,
    this.numeric = false,
    this.role = ReportCellRole.meta,
    this.exportOnly = false,
  });
  final String label;

  /// Fixed width; null shares the spare width.
  final double? width;
  final bool numeric;
  final ReportCellRole role;

  /// Left out on screen and in print; kept in the CSV.
  final bool exportOnly;
}

class ReportCell {
  const ReportCell(this.text, {String? csv, this.tone = ReportTone.normal}) : csv = csv ?? text;

  /// Negative amounts read as money out: `− 1,800 EGP`.
  factory ReportCell.money(int minor, {ReportTone tone = ReportTone.normal}) => ReportCell(
    minor < 0 ? '− ${Money.format(-minor)}' : Money.format(minor),
    csv: '${minor < 0 ? '-' : ''}${Money.editable(minor.abs())}',
    tone: tone,
  );

  factory ReportCell.count(int count) => ReportCell('$count');

  factory ReportCell.day(DateTime day) =>
      ReportCell(Formatters.formatDateMedium(day), csv: ReportRange.isoDay(day));

  factory ReportCell.time(DateTime time) {
    final DateTime local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return ReportCell(
      Formatters.formatDateTime(time),
      csv: '${ReportRange.isoDay(local)} ${two(local.hour)}:${two(local.minute)}',
    );
  }

  final String text;
  final String csv;
  final ReportTone tone;
}

class ReportRow {
  const ReportRow(this.cells, {this.location, this.detail});
  final List<ReportCell> cells;

  /// Route opened when the row is activated.
  final String? location;

  /// Rows revealed under this one when it is expanded.
  final ReportSheet? detail;
}

class ReportSheet {
  const ReportSheet({required this.columns, required this.rows, this.footer});
  final List<ReportColumn> columns;
  final List<ReportRow> rows;

  /// Totals row, aligned to [columns].
  final List<ReportCell>? footer;

  bool get isActionable => rows.any((row) => row.location != null || row.detail != null);

  /// Width needed before aligned columns are readable.
  double get minWidth {
    double width = AppSizes.p32 + (isActionable ? AppSizes.iconDefault + AppSizes.p8 : 0);
    for (final column in columns.where((column) => !column.exportOnly)) {
      width += column.width ?? AppSizes.reportTextColumnMinWidth;
    }
    return width;
  }
}

class ReportSection {
  const ReportSection({required this.sheet, this.title, this.note, this.emptyMessage});
  final String? title;
  final String? note;
  final ReportSheet sheet;

  /// Shown in place of an empty table; a section without one is hidden.
  final String? emptyMessage;
}

class ReportFigure {
  const ReportFigure(this.label, this.value, {this.tone = ReportTone.normal});
  final String label;
  final String value;
  final ReportTone tone;
}

/// A report ready for the screen, the CSV file and the printed page.
class ReportView {
  const ReportView({required this.figures, required this.sections, required this.export});
  final List<ReportFigure> figures;
  final List<ReportSection> sections;

  /// The detail rows written to the CSV file.
  final ReportSheet export;
}
