import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/domain/package_kind.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Modal form sheet to add or edit a clinic package.
///
/// Top ChoiceChip sets the package kind. Count fields are shown only for the
/// buckets that the chosen kind credits (Session / Traction / Combined).
class PackageFormSheet extends StatefulWidget {
  /// Creates a [PackageFormSheet].
  const PackageFormSheet({
    this.package,
    required this.onSave,
    super.key,
  });

  /// The clinic package being edited (null for creation mode).
  final ClinicPackage? package;

  /// Callback when package form is submitted and validated.
  final void Function(ClinicPackage package) onSave;

  @override
  State<PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<PackageFormSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  PackageKind _kind = PackageKind.session;

  InputDecoration _buildDecoration({required String labelText, String? hintText}) {
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      hintText: hintText,
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted),
      contentPadding: AppSizes.paddingCell,
      enabledBorder: borderBase,
      disabledBorder: borderBase,
      focusedBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.borderStrong, width: AppSizes.borderWidthFocused),
      ),
      errorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidth),
      ),
      focusedErrorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidthFocused),
      ),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final String name = values['name'] as String;
      final double price = double.parse(values['price'] as String);
      final int sessionCount = int.tryParse((values['session_count'] as String?) ?? '0') ?? 0;
      final int tractionsCount = int.tryParse((values['tractions_count'] as String?) ?? '0') ?? 0;

      final ClinicPackage newPackage = ClinicPackage(
        name: name,
        kind: _kind,
        sessionCount: sessionCount,
        tractionsCount: tractionsCount,
        price: price,
      );

      widget.onSave(newPackage);
    }
  }

  String? _validateByKind(String? value) {
    if (value == null || value.isEmpty) return AppStrings.sessionCountRequired;
    final int? parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) return AppStrings.sessionCountPositive;
    if (_kind != PackageKind.traction && parsed <= 0 && _kind == PackageKind.session) {
      return AppStrings.sessionCountPositive;
    }
    if (_kind == PackageKind.traction && parsed <= 0) {
      return AppStrings.tractionsCountPositive;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.package != null) _kind = widget.package!.kind;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.package != null;
    final bool showSession = _kind != PackageKind.traction;
    final bool showTraction = _kind != PackageKind.session;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.p24,
        right: AppSizes.p24,
        top: AppSizes.p24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p24,
      ),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? AppStrings.editPackage : AppStrings.addPackage,
                  style: AppTextStyles.headingSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p20),

            // ── Name Field ──
            FormBuilderTextField(
              name: 'name',
              initialValue: widget.package?.name,
              textCapitalization: TextCapitalization.words,
              decoration: _buildDecoration(
                labelText: AppStrings.packageName,
                hintText: 'e.g. Gold Combo',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: AppStrings.nameRequired),
              ]),
            ),
            const SizedBox(height: AppSizes.p16),

            // ── Kind selector ──
            Text(
              AppStrings.packageKindLabel,
              style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.p8),
            Wrap(
              spacing: AppSizes.p8,
              children: PackageKind.values.map((kind) {
                final bool active = kind == _kind;
                final String label = switch (kind) {
                  PackageKind.session => AppStrings.packageKindSession,
                  PackageKind.traction => AppStrings.packageKindTraction,
                  PackageKind.combined => AppStrings.packageKindCombined,
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: active,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTextStyles.captionMedium.copyWith(
                    color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
                  ),
                  onSelected: (_) => setState(() => _kind = kind),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.p16),

            // ── Conditional count fields ──
            Row(
              children: [
                if (showSession)
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'session_count',
                      initialValue: widget.package?.sessionCount.toString() ?? '0',
                      keyboardType: TextInputType.number,
                      decoration: _buildDecoration(
                        labelText: AppStrings.sessionCount,
                        hintText: 'e.g. 10',
                      ),
                      validator: _validateByKind,
                    ),
                  ),
                if (showSession && showTraction) const SizedBox(width: AppSizes.p12),
                if (showTraction)
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'tractions_count',
                      initialValue: widget.package?.tractionsCount.toString() ?? '0',
                      keyboardType: TextInputType.number,
                      decoration: _buildDecoration(
                        labelText: AppStrings.tractionsCount,
                        hintText: 'e.g. 4',
                      ),
                      validator: _validateByKind,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              AppStrings.packageCountsAtLeastOne,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSizes.p16),

            // ── Price Field ──
            FormBuilderTextField(
              name: 'price',
              initialValue: widget.package?.price.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _buildDecoration(
                labelText: AppStrings.price,
                hintText: 'e.g. 5000',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: AppStrings.priceRequired),
                FormBuilderValidators.numeric(errorText: AppStrings.pricePositive),
                (String? val) {
                  if (val != null && val.isNotEmpty) {
                    final double? parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) {
                      return AppStrings.pricePositive;
                    }
                  }
                  return null;
                },
              ]),
            ),
            const SizedBox(height: AppSizes.p24),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    labelText: AppStrings.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    variant: AppButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: AppButton(
                    labelText: isEdit ? AppStrings.save : AppStrings.add,
                    onPressed: _submit,
                    variant: AppButtonVariant.primary,
                    debounceMs: 1000,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
