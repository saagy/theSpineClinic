import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/form_field_pair.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/labeled_form_field.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../domain/service_catalog_item.dart';
import 'service_catalog_labels.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoices;

/// Field controllers and choices owned by the service form.
class ServiceFormInput {
  ServiceFormInput({
    required this.name,
    required this.price,
    required this.sessions,
    required this.type,
    required this.package,
    required this.credit,
    required this.active,
  });
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController sessions;
  ServiceType type;
  bool package;
  bool credit;
  bool active;

  bool get isPackage => type.usesSessions && package;
  int? get priceMinor => Money.parseMinor(price.text);
  int? get sessionCount => isPackage ? int.tryParse(sessions.text.trim()) : 1;
}

class ServiceFormFields extends StatelessWidget {
  const ServiceFormFields({
    super.key,
    required this.input,
    required this.original,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });
  final ServiceFormInput input;
  final ServiceCatalogItem? original;
  final bool enabled;
  final ValueChanged<VoidCallback> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final int? price = input.priceMinor;
    final int? sessions = input.sessionCount;
    final bool showPerSession =
        input.isPackage && price != null && price > 0 && sessions != null && sessions >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
          child: Text(
            _t.serviceFormHelp,
            style: AppTextStyles.bodySecondary.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        FormSection(
          title: _t.sectionService,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ServiceTextInput(
                label: _t.name,
                hint: _t.nameHint,
                controller: input.name,
                enabled: enabled,
                maxLength: 120,
                validator: (text) => text.isEmpty ? _t.nameRequired : null,
              ),
              const SizedBox(height: AppSizes.p20),
              LabeledFormField(
                label: _t.type,
                enabled: enabled,
                child: RecordMenuSelect<ServiceType>(
                  label: _t.type,
                  value: input.type,
                  isField: true,
                  decoration: appInputDecoration(context, enabled: enabled),
                  options: [
                    for (final type in ServiceType.values)
                      RecordMenuAction(type, type.label, type.icon),
                  ],
                  onChanged: enabled ? (type) => onChanged(() => _setType(type)) : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        FormSection(
          title: _t.sectionPrice,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (input.type.usesSessions) ...[
                LabeledFormField(
                  label: _t.soldAs,
                  enabled: enabled,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(_t.singleSession)),
                      ButtonSegment(value: true, label: Text(_t.package)),
                    ],
                    selected: {input.package},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
                      minimumSize: WidgetStatePropertyAll(
                        Size(AppSizes.tappableMin, AppSizes.tappableMin),
                      ),
                    ),
                    onSelectionChanged: enabled
                        ? (value) => onChanged(() => input.package = value.first)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSizes.p20),
              ],
              FormFieldPair(
                first: input.isPackage
                    ? ServiceTextInput(
                        label: _t.sessionsInPackage,
                        controller: input.sessions,
                        enabled: enabled,
                        numeric: true,
                        maxLength: 3,
                        validator: (text) {
                          final int? value = int.tryParse(text);
                          return value == null || value < 2 || value > 100
                              ? _t.sessionsInvalid
                              : null;
                        },
                      )
                    : _priceField(),
                second: input.isPackage ? _priceField() : null,
              ),
              if (showPerSession)
                ServiceFieldNote(
                  _t.perSession(Money.format((price / sessions).round())),
                  emphasis: true,
                ),
              if (input.isPackage) ServiceFieldNote(_t.packageHelp),
              if (original != null && price != null && price != original!.priceMinor)
                ServiceFieldNote(_t.priceChangeHelp),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        FormSection(
          title: _t.sectionCredit,
          child: ServiceSettingSwitch(
            title: _t.creditDoctors,
            description: _t.creditHelp,
            value: input.credit,
            onChanged: enabled ? (value) => onChanged(() => input.credit = value) : null,
          ),
        ),
        if (original != null) ...[
          const SizedBox(height: AppSizes.p24),
          FormSection(
            title: _t.sectionAvailability,
            child: ServiceSettingSwitch(
              title: _t.availableOnInvoices,
              description: _t.availabilityHelp,
              value: input.active,
              onChanged: enabled ? (value) => onChanged(() => input.active = value) : null,
            ),
          ),
        ],
      ],
    );
  }

  Widget _priceField() => ServiceTextInput(
    label: _t.price,
    controller: input.price,
    enabled: enabled,
    numeric: true,
    decimal: true,
    maxLength: 13,
    onSubmitted: onSubmit,
    validator: (text) {
      final int? value = Money.parseMinor(text);
      return value == null || value <= 0 ? _t.priceInvalid : null;
    },
  );

  /// Spinal traction is usually done without a doctor, so switching to it
  /// turns doctor credit off; other types turn it back on. Saved services
  /// keep whatever the user chose.
  void _setType(ServiceType type) {
    if (original == null && type != input.type) {
      input.credit = type != ServiceType.tractionSession;
    }
    input.type = type;
  }
}
