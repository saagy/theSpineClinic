import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../auth/domain/staff.dart';
import '../../domain/invoice_detail.dart';
import '../../domain/service_catalog_item.dart';
import 'invoice_form_input.dart';
import 'invoice_line_editor.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoiceDetail;

/// Starts a correction from the original invoice. Lines keep their quantity
/// and doctors but take the service's current catalog entry; services that
/// are no longer sold cannot be invoiced and are returned in `dropped`.
({InvoiceFormInput input, List<String> dropped}) prefillCorrection(
  InvoiceDetail invoice,
  List<ServiceCatalogItem> activeServices,
  List<Staff> doctors,
) {
  final input = InvoiceFormInput(branch: invoice.branch, date: invoice.summary.invoiceDate);
  final byId = {for (final service in activeServices) service.id: service};
  final activeDoctors = {
    for (final doctor in doctors)
      if (doctor.isActive) doctor.id: doctor,
  };
  final dropped = <String>[];
  for (final line in invoice.lines) {
    final ServiceCatalogItem? service = byId[line.serviceId];
    if (service == null) {
      dropped.add(line.serviceName);
      continue;
    }
    input.lines.add(InvoiceLineInput(
      key: input.nextKey(),
      service: service,
      quantity: line.quantity,
      doctors: [
        if (service.creditsDoctors)
          for (final doctor in line.doctors) ?activeDoctors[doctor.id],
      ],
    ));
  }
  input.setDiscount(invoice.discountKind, invoice.discountValue);
  input.note.text = invoice.note ?? '';
  return (input: input, dropped: dropped);
}

/// Explains what saving does, and names any service that had to be left out.
class CorrectionNotice extends StatelessWidget {
  const CorrectionNotice({super.key, required this.number, required this.dropped});
  final String number;
  final List<String> dropped;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t.correctHelp(number), style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant)),
        if (dropped.isNotEmpty) ...[
          const SizedBox(height: AppSizes.p12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: clinic.warningContainer,
              border: Border.all(color: clinic.warning),
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: AppSizes.iconDefault, color: clinic.warning),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Text(
                      _t.droppedServices(dropped.join(', ')),
                      style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CorrectionReasonSection extends StatelessWidget {
  const CorrectionReasonSection({super.key, required this.controller, required this.enabled});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormSection(
    title: _t.correctionReason,
    child: ServiceTextInput(
      label: _t.reason,
      hint: _t.reasonHint,
      controller: controller,
      enabled: enabled,
      maxLength: 500,
      validator: (text) => text.isEmpty ? _t.reasonRequired : null,
    ),
  );
}

/// The correction form's sections, one under another.
class CorrectionLayout extends StatelessWidget {
  const CorrectionLayout({super.key, required this.sections});
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, section) in sections.indexed) ...[
        if (index > 0) const SizedBox(height: AppSizes.p24),
        section,
      ],
    ],
  );
}
