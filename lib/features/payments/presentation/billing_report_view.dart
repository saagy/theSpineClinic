import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';

/// How a cell is placed when a table has no room for columns: the title
/// leads the row with the lead amount opposite it, detail values (what the
/// row is about) share the next line, then the quieter meta values and the
/// figures with their column labels.
enum ReportCellRole { title, detail, meta, figure, lead }

enum ReportTone { normal, muted, warning }

/// Keeps each amount and its currency on one line when text wraps.
String reportUnbroken(String text) => text.replaceAll(' EGP', ' EGP');

class ReportColumn {
  const ReportColumn(
    this.label, {
    this.width,
    this.numeric = false,
    this.role = ReportCellRole.meta,
  });
  final String label;

  /// Fixed width; null shares the spare width.
  final double? width;
  final bool numeric;
  final ReportCellRole role;
}

class ReportCell {
  const ReportCell(this.text, {this.sub, this.tone = ReportTone.normal});

  /// Negative amounts read as money out: `− 1,800 EGP`.
  factory ReportCell.money(int minor, {ReportTone tone = ReportTone.normal}) =>
      ReportCell(minor < 0 ? '− ${Money.format(-minor)}' : Money.format(minor), tone: tone);

  factory ReportCell.count(int count) => ReportCell('$count');

  factory ReportCell.day(DateTime day) => ReportCell(Formatters.formatDateMedium(day));

  /// The date with the time beneath, or only the time when the report
  /// covers one day.
  factory ReportCell.when(DateTime at, {bool timeOnly = false}) => timeOnly
      ? ReportCell(Formatters.formatTime(at))
      : ReportCell(Formatters.formatDateMedium(at), sub: Formatters.formatTime(at));

  /// The patient's name with their permanent ID beneath.
  factory ReportCell.patient(String name, int fileNumber) =>
      ReportCell(name, sub: AppStrings.patientIdLabel(fileNumber));

  final String text;

  /// A quieter second line, such as the patient ID under a name.
  final String? sub;
  final ReportTone tone;

  /// Both lines on one line, for stacked rows.
  String get inline => sub == null ? text : '$text $sub';
}

class ReportRow {
  const ReportRow(this.cells, {this.location, this.detail, this.doctor});
  final List<ReportCell> cells;

  /// Route opened when the row is activated.
  final String? location;

  /// Rows revealed under this one when it is expanded.
  final ReportSheet? detail;

  /// Doctor the report narrows to when the row is activated.
  final ({String id, String name})? doctor;

  bool get isActionable => location != null || detail != null || doctor != null;

  /// Tells this row apart from its neighbours across reloads: what it opens,
  /// else its first cell (such as the doctor or service it groups).
  Object get identity =>
      location ?? doctor?.id ?? (cells.isEmpty ? '' : '${cells.first.text}|${cells.first.sub}');
}

class ReportSheet {
  const ReportSheet({required this.columns, required this.rows, this.footer, this.detailHints});
  final List<ReportColumn> columns;
  final List<ReportRow> rows;

  /// What expanding and collapsing a row does, for screen readers; null
  /// means the rows hold invoices.
  final ({String show, String hide})? detailHints;

  /// Totals row, aligned to [columns].
  final List<ReportCell>? footer;

  bool get isActionable => rows.any((row) => row.isActionable);

  /// Width needed before aligned columns are readable.
  double get minWidth {
    double width = AppSizes.p32 + (isActionable ? AppSizes.iconDefault + AppSizes.p8 : 0);
    for (final column in columns) {
      width += column.width ?? AppSizes.reportTextColumnMinWidth;
    }
    return width;
  }
}

class ReportSection {
  const ReportSection({
    required this.sheet,
    this.title,
    this.note,
    this.emptyMessage,
    this.printOnly = false,
    this.newPage = false,
  });
  final String? title;
  final String? note;
  final ReportSheet sheet;

  /// Printed but not shown on screen, where the same rows open from a
  /// summary row instead.
  final bool printOnly;

  /// Starts on a new printed page.
  final bool newPage;

  /// Shown in place of an empty table; a section without one is hidden.
  final String? emptyMessage;
}

class ReportFigure {
  const ReportFigure(this.label, this.value, {this.caption, this.tone = ReportTone.normal});
  final String label;
  final String value;

  /// How the value is made up, such as `Received 22,450` over `Refunded 1,000`.
  final String? caption;
  final ReportTone tone;
}

/// A report ready for the screen and the printed page.
class ReportView {
  const ReportView({required this.figures, required this.sections});
  final List<ReportFigure> figures;
  final List<ReportSection> sections;
}
