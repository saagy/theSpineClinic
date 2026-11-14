import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_table_pagination.dart';
import '../billing_report_view.dart';
import 'report_table_row.dart';

const _t = AppStrings.billingReports;

/// A report table, one page of rows at a time. Columns align when the
/// width allows; otherwise each row stacks. Rows open their record or
/// expand to show the rows behind them.
class ReportTable extends StatefulWidget {
  const ReportTable({super.key, required this.sheet, this.nested = false, this.onDoctor});
  final ReportSheet sheet;

  /// Narrows the report to a doctor whose row was activated.
  final void Function(String id, String name)? onDoctor;

  /// Shown inside an expanded row, without its own surface.
  final bool nested;

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  int _page = 0;

  /// Expanded rows by [ReportRow.identity], so they stay open when the
  /// same report reloads with rows added or removed.
  final Set<Object> _expanded = {};

  // A different report gets a new table (see ReportBody); a reload of the
  // same one keeps its page, clamped in build, and its open rows.
  @override
  void didUpdateWidget(covariant ReportTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sheet, widget.sheet)) {
      final Set<Object> rows = {for (final row in widget.sheet.rows) row.identity};
      _expanded.retainWhere(rows.contains);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final colors = Theme.of(context).colorScheme;
    const int size = AppSizes.reportPageSize;
    final int pages = (sheet.rows.length / size).ceil().clamp(1, 1 << 30);
    final int page = _page.clamp(0, pages - 1);
    final int first = page * size;
    final divider = Divider(
      height: AppSizes.borderWidth,
      thickness: AppSizes.borderWidth,
      color: colors.outlineVariant,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final bool wide =
            box.maxWidth >= sheet.minWidth && MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide && widget.nested) ...[
              ReportTableHeader(columns: sheet.columns, reserveTrailing: sheet.isActionable),
              divider,
            ],
            for (int index = first; index < sheet.rows.length && index < first + size; index++) ...[
              if (index > first) divider,
              _row(context, index, wide),
              if (_expanded.contains(sheet.rows[index].identity) &&
                  sheet.rows[index].detail != null) ...[
                divider,
                Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ReportTable(
                    key: ValueKey(sheet.rows[index].identity),
                    sheet: sheet.rows[index].detail!,
                    nested: true,
                  ),
                ),
              ],
            ],
            if (sheet.footer != null && sheet.rows.isNotEmpty) ...[
              divider,
              ReportTableRow(
                columns: sheet.columns,
                cells: sheet.footer!,
                wide: wide,
                strong: true,
                trailing: sheet.isActionable ? const SizedBox(width: AppSizes.iconDefault) : null,
              ),
            ],
            if (pages > 1)
              AppTablePagination(
                currentPage: page + 1,
                totalPages: pages,
                totalCount: sheet.rows.length,
                pageSize: size,
                hasPrevious: page > 0,
                hasNext: page < pages - 1,
                onPrevious: () => setState(() => _page = page - 1),
                onNext: () => setState(() => _page = page + 1),
                entityLabel: _t.rowsLabel,
              ),
          ],
        );
        if (widget.nested) return body;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              ReportTableHeader(columns: sheet.columns, reserveTrailing: sheet.isActionable),
            Material(
              color: colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(AppSizes.r12),
              ),
              child: body,
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, int index, bool wide) {
    final ReportRow row = widget.sheet.rows[index];
    final colors = Theme.of(context).colorScheme;
    final bool open = _expanded.contains(row.identity);
    final doctor = widget.onDoctor == null ? null : row.doctor;
    final IconData? icon = row.detail != null
        ? (open ? Icons.expand_less : Icons.expand_more)
        : row.location != null || doctor != null
        ? Icons.chevron_right
        : null;
    final content = ReportTableRow(
      columns: widget.sheet.columns,
      cells: row.cells,
      wide: wide,
      trailing: icon != null
          ? Icon(icon, size: AppSizes.iconDefault, color: colors.onSurfaceVariant)
          : widget.sheet.isActionable
          ? const SizedBox(width: AppSizes.iconDefault)
          : null,
    );
    if (icon == null) return content;
    return Semantics(
      button: true,
      expanded: row.detail == null ? null : open,
      hint: doctor != null
          ? _t.showDoctor
          : row.detail == null
          ? _t.openRecord
          : open
          ? widget.sheet.detailHints?.hide ?? _t.hideDetail
          : widget.sheet.detailHints?.show ?? _t.showDetail,
      child: InkWell(
        onTap: row.detail != null
            ? () => setState(() => open ? _expanded.remove(row.identity) : _expanded.add(row.identity))
            : doctor != null
            ? () => widget.onDoctor!(doctor.id, doctor.name)
            : () => context.push(row.location!),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          child: Align(alignment: Alignment.centerLeft, child: content),
        ),
      ),
    );
  }
}
