import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../billing_report_view.dart';

/// Keeps the dot with the value before it when stacked text wraps.
const String _separator = ' · ';

/// Lays visible columns out with fixed or shared widths.
List<Widget> _aligned(
  List<ReportColumn> columns,
  Widget Function(int index, ReportColumn column) cell,
) {
  final visible = [
    for (final (index, column) in columns.indexed)
      if (!column.exportOnly) (index, column),
  ];
  return [
    for (final (position, (index, column)) in visible.indexed)
      () {
        final Widget content = Padding(
          padding: EdgeInsets.only(right: position == visible.length - 1 ? 0 : AppSizes.p12),
          child: cell(index, column),
        );
        return column.width == null
            ? Expanded(child: content)
            : SizedBox(width: column.width, child: content);
      }(),
  ];
}

/// One report row: aligned columns when [wide], otherwise the title and lead
/// amount on the first line with the remaining values beneath.
class ReportTableRow extends StatelessWidget {
  const ReportTableRow({
    super.key,
    required this.columns,
    required this.cells,
    required this.wide,
    this.strong = false,
    this.trailing,
  });
  final List<ReportColumn> columns;
  final List<ReportCell> cells;
  final bool wide;

  /// Totals rows carry more weight.
  final bool strong;

  /// Chevron or expand icon; an empty box keeps columns aligned.
  final Widget? trailing;

  Color _color(BuildContext context, ReportTone tone) => switch (tone) {
    ReportTone.normal => Theme.of(context).colorScheme.onSurface,
    ReportTone.muted => Theme.of(context).colorScheme.onSurfaceVariant,
    ReportTone.warning => ClinicColors.of(context).warning,
  };

  TextStyle _style(BuildContext context, ReportColumn column, ReportCell cell) {
    final bool heavy = strong || column.role == ReportCellRole.lead;
    final TextStyle base = column.numeric
        ? AppTextStyles.number.copyWith(fontWeight: heavy ? FontWeight.w600 : FontWeight.w500)
        : strong
        ? AppTextStyles.bodyBold
        : column.role == ReportCellRole.title
        ? AppTextStyles.bodyMedium
        : AppTextStyles.body;
    return base.copyWith(color: _color(context, cell.tone));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSizes.paddingCell,
    child: wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._aligned(
                columns,
                (index, column) => Text(
                  cells[index].text,
                  textAlign: column.numeric ? TextAlign.end : TextAlign.start,
                  style: _style(context, column, cells[index]),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSizes.p8), trailing!],
            ],
          )
        : _stacked(context),
  );

  Widget _stacked(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final bool large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final visible = [
      for (final (index, column) in columns.indexed)
        if (!column.exportOnly && cells[index].text.isNotEmpty) (column, cells[index]),
    ];
    (ReportColumn, ReportCell)? find(ReportCellRole role) =>
        visible.where((item) => item.$1.role == role).firstOrNull;
    final title = find(ReportCellRole.title);
    final lead = find(ReportCellRole.lead);
    final String meta = [
      for (final (column, cell) in visible)
        if (column.role == ReportCellRole.meta) cell.text,
    ].join(_separator);
    final String figures = [
      for (final (column, cell) in visible)
        if (column.role == ReportCellRole.figure) '${column.label} ${cell.text}',
    ].join(_separator);
    // With other figures on the row, the lead amount says what it is.
    final Widget? amount = lead == null
        ? null
        : Column(
            crossAxisAlignment: large ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(lead.$2.text, style: _style(context, lead.$1, lead.$2)),
              if (figures.isNotEmpty) Text(lead.$1.label, style: muted),
            ],
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title.$2.text,
                  style: AppTextStyles.bodyBold.copyWith(color: _color(context, title.$2.tone)),
                ),
              if (meta.isNotEmpty) Text(meta, style: muted),
              if (figures.isNotEmpty)
                Text(
                  figures,
                  style: muted.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              if (large && amount != null) ...[const SizedBox(height: AppSizes.p4), amount],
            ],
          ),
        ),
        if (!large && amount != null) ...[const SizedBox(width: AppSizes.p12), amount],
        if (trailing != null) ...[const SizedBox(width: AppSizes.p4), trailing!],
      ],
    );
  }
}

/// Column labels above a table with aligned columns.
class ReportTableHeader extends StatelessWidget {
  const ReportTableHeader({super.key, required this.columns, required this.reserveTrailing});
  final List<ReportColumn> columns;
  final bool reserveTrailing;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionMedium.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      child: Row(
        children: [
          ..._aligned(
            columns,
            (_, column) => Text(
              column.label,
              style: style,
              textAlign: column.numeric ? TextAlign.end : TextAlign.start,
            ),
          ),
          if (reserveTrailing) const SizedBox(width: AppSizes.p8 + AppSizes.iconDefault),
        ],
      ),
    );
  }
}
