import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../domain/invoice_summary.dart';

const _t = AppStrings.invoices;

extension InvoiceStatusText on InvoiceStatus {
  String get label => switch (this) {
    InvoiceStatus.paid => _t.statusPaid,
    InvoiceStatus.partiallyPaid => _t.statusPartial,
    InvoiceStatus.unpaid => _t.statusUnpaid,
    InvoiceStatus.partlyRefunded => _t.statusPartlyRefunded,
    InvoiceStatus.refunded => _t.statusRefunded,
    InvoiceStatus.voided => _t.statusVoided,
  };
}

/// Status as icon plus text, so meaning never depends on color alone.
class InvoiceStatusLabel extends StatelessWidget {
  const InvoiceStatusLabel(this.status, {super.key});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final clinic = ClinicColors.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (IconData icon, Color color) = switch (status) {
      InvoiceStatus.paid => (Icons.check_circle, clinic.success),
      InvoiceStatus.partiallyPaid => (Icons.timelapse, clinic.warning),
      InvoiceStatus.unpaid => (Icons.radio_button_unchecked, clinic.warning),
      InvoiceStatus.partlyRefunded || InvoiceStatus.refunded => (Icons.undo, muted),
      InvoiceStatus.voided => (Icons.block, muted),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: color),
        const SizedBox(width: AppSizes.p4),
        Flexible(
          child: Text(status.label, style: AppTextStyles.captionBold.copyWith(color: color)),
        ),
      ],
    );
  }
}
