import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/doctor_select_field.dart';
import '../../../auth/domain/staff.dart';
import '../../domain/invoice_draft.dart';
import '../../domain/service_catalog_item.dart';
import 'service_catalog_labels.dart';

const _t = AppStrings.invoices;

/// Form state for one invoice line. [key] keeps each line's widgets stable
/// while lines are added and removed.
class InvoiceLineInput {
  InvoiceLineInput({required this.key, required this.service, this.quantity = 1, this.doctors = const []});
  final int key;
  ServiceCatalogItem service;
  int quantity;
  List<Staff> doctors;

  InvoiceLineDraft toDraft() => InvoiceLineDraft(
    service: service,
    quantity: quantity,
    doctorIds: service.creditsDoctors ? [for (final doctor in doctors) doctor.id] : const [],
  );
}

class InvoiceLineEditor extends StatelessWidget {
  const InvoiceLineEditor({
    super.key,
    required this.line,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });
  final InvoiceLineInput line;
  final bool enabled;
  final ValueChanged<VoidCallback> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final service = line.service;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: AppTextStyles.bodyBold),
                    Text(
                      [service.soldAs, _t.each(Money.format(service.priceMinor))].join(' · '),
                      style: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              IconButton(
                tooltip: _t.removeLine,
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.tappableMin,
                  height: AppSizes.tappableMin,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              QuantityStepper(
                value: line.quantity,
                onChanged: enabled ? (value) => onChanged(() => line.quantity = value) : null,
              ),
              const Spacer(),
              Text(
                Money.format(service.priceMinor * line.quantity),
                style: AppTextStyles.number.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          if (service.creditsDoctors) ...[
            DoctorSelectField(
              key: ValueKey('line-doctors-${line.key}'),
              initialValue: line.doctors,
              enabled: enabled,
              onSavedDoctors: null,
              onChanged: (doctors) => onChanged(() => line.doctors = doctors),
            ),
            const SizedBox(height: AppSizes.p4),
            Text(_t.doctorsHelp, style: muted),
          ] else
            Text(_t.noDoctorCredit, style: muted),
        ],
      ),
    );
  }
}

/// Compact quantity control with 44px targets.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100,
    this.label,
    this.decreaseTooltip,
    this.increaseTooltip,
  });
  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  final String? label;
  final String? decreaseTooltip;
  final String? increaseTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const box = BoxConstraints.tightFor(width: AppSizes.tappableMin, height: AppSizes.tappableMin);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: decreaseTooltip ?? _t.decrease,
            constraints: box,
            icon: const Icon(Icons.remove, size: AppSizes.iconSmall),
            onPressed: onChanged == null || value <= min ? null : () => onChanged!(value - 1),
          ),
          SizedBox(
            width: AppSizes.quantityValueWidth,
            child: Semantics(
              label: label ?? _t.quantity,
              value: '$value',
              child: Text('$value', textAlign: TextAlign.center, style: AppTextStyles.number),
            ),
          ),
          IconButton(
            tooltip: increaseTooltip ?? _t.increase,
            constraints: box,
            icon: const Icon(Icons.add, size: AppSizes.iconSmall),
            onPressed: onChanged == null || value >= max ? null : () => onChanged!(value + 1),
          ),
        ],
      ),
    );
  }
}
