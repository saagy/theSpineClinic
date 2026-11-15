import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money.dart';
import '../../../patient/presentation/patient_navigation.dart';
import '../../../patient/presentation/patient_workspace_tab.dart';
import '../../domain/invoice_detail.dart';
import 'invoice_patient_identity.dart';
import 'invoice_status_label.dart';

const _t = AppStrings.invoiceDetail;

/// Who the invoice is for, its state, and links to related invoices. The
/// patient opens on their payments unless their record is right underneath.
class InvoiceDetailHeader extends ConsumerWidget {
  const InvoiceDetailHeader({super.key, required this.invoice});
  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final summary = invoice.summary;
    final VoidStamp? voided = invoice.voided;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InvoicePatientIdentity(
                name: invoice.patientName,
                details: [
                  if (invoice.fileNumber != null) AppStrings.patientIdLabel(invoice.fileNumber!),
                  Formatters.formatDateMedium(summary.invoiceDate),
                  summary.branch.displayLabel,
                ].join(' · '),
                onOpen: patientRecordIsBelow(context, invoice.patientId)
                    ? null
                    : () => openPatientRecordFrom(
                        context,
                        ref,
                        invoice.patientId,
                        tab: PatientWorkspaceTab.payments,
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.p4),
              child: InvoiceStatusLabel(summary.displayStatus),
            ),
          ],
        ),
        if (voided != null) ...[
          const SizedBox(height: AppSizes.p12),
          _Notice(
            title: _t.voidedInvoice,
            lines: [
              _t.voidedBy(voided.byName, Formatters.formatDateTime(voided.at)),
              _t.reasonLine(voided.reason),
            ],
          ),
        ],
        for (final (InvoiceRef? other, String Function(String) label) in [
          (invoice.replacedBy, _t.correctedBy),
          (invoice.replaces, _t.corrects),
        ])
          if (other != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.pushReplacement(
                  AppRoutes.invoiceDetailLocation(invoice.patientId, other.id),
                ),
                icon: const Icon(Icons.arrow_forward, size: AppSizes.iconSmall),
                label: Text(label(other.displayNumber), style: AppTextStyles.bodyBold),
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        if (invoice.note != null) ...[
          const SizedBox(height: AppSizes.p8),
          Text('${_t.note}: ${invoice.note!}', style: AppTextStyles.body.copyWith(color: colors.onSurface)),
        ],
      ],
    );
  }
}

/// A quiet bordered note for the voided state.
class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClinicColors.of(context).neutralContainer,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface)),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.p4),
                child: Text(
                  line,
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Invoice value, money paid and the amount still due, in one bordered strip.
class InvoiceMoneyFigures extends StatelessWidget {
  const InvoiceMoneyFigures({super.key, required this.invoice});
  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool voided = invoice.isVoided;
    final Color strong = voided ? colors.onSurfaceVariant : colors.onSurface;
    final figures = [
      (_t.invoiceValue, invoice.valueMinor, strong),
      (_t.paid, invoice.collectedMinor, strong),
      (_t.due, invoice.dueMinor, invoice.dueMinor > 0 ? ClinicColors.of(context).warning : strong),
    ];
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final cells = [
      for (final (String label, int minor, Color color) in figures)
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppSizes.p4),
              Text(
                Money.format(minor),
                style: AppTextStyles.number.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
    ];
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, cell) in cells.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSizes.p12),
                    cell,
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final cell in cells) Expanded(child: cell)],
              ),
      ),
    );
  }
}
