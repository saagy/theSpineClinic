import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/labeled_form_field.dart';

/// A labeled on/off setting with its consequence explained below the title.
class ServiceSettingSwitch extends StatelessWidget {
  const ServiceSettingSwitch({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(AppSizes.r8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyBold),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// External-label text input sharing the app's form field chrome.
class ServiceTextInput extends StatelessWidget {
  const ServiceTextInput({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    required this.validator,
    this.hint,
    this.numeric = false,
    this.decimal = false,
    this.maxLength,
    this.onSubmitted,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String text) validator;
  final String? hint;
  final bool numeric;
  final bool decimal;
  final int? maxLength;
  final VoidCallback? onSubmitted;

  /// Called for the user's own edits only, not for changes made in code.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => LabeledFormField(
    label: label,
    enabled: enabled,
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.onSurface),
      textCapitalization: numeric ? TextCapitalization.none : TextCapitalization.sentences,
      keyboardType: numeric ? TextInputType.numberWithOptions(decimal: decimal) : TextInputType.text,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      onChanged: onChanged,
      inputFormatters: [
        if (numeric)
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: appInputDecoration(context, enabled: enabled, hintText: hint),
      validator: (text) => validator((text ?? '').trim()),
    ),
  );
}

/// Supporting text under a field group.
class ServiceFieldNote extends StatelessWidget {
  const ServiceFieldNote(this.text, {super.key, this.emphasis = false});
  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.p8),
    child: Text(
      text,
      style: (emphasis ? AppTextStyles.captionBold : AppTextStyles.caption).copyWith(
        color: emphasis
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
