import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../billing_report_view.dart';

/// A report's headline totals in one bordered strip.
class ReportFigures extends StatelessWidget {
  const ReportFigures({super.key, required this.figures});
  final List<ReportFigure> figures;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: LayoutBuilder(
          builder: (context, box) {
            final bool large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final int fit = (box.maxWidth / AppSizes.reportFigureMinWidth).floor();
            final int perRow = large ? 1 : fit >= figures.length ? figures.length : 2;
            return Column(
              children: [
                for (int start = 0; start < figures.length; start += perRow) ...[
                  if (start > 0) const SizedBox(height: AppSizes.p16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int index = start; index < start + perRow; index++)
                        Expanded(
                          child: index < figures.length
                              ? _Figure(figures[index])
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.figure);
  final ReportFigure figure;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(figure.label, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSizes.p4),
          Text(
            figure.value,
            style: AppTextStyles.cardTitle.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: figure.tone == ReportTone.warning
                  ? ClinicColors.of(context).warning
                  : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
