import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Staged permission selection without input-field chrome.
class StaffPermissionField extends StatelessWidget {
  const StaffPermissionField({
    super.key,
    required this.name,
    required this.title,
    required this.description,
    required this.enabled,
    required this.initialValue,
  });
  final String name;
  final String title;
  final String description;
  final bool enabled;
  final bool initialValue;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
    child: FormBuilderCheckbox(
      name: name,
      enabled: enabled,
      initialValue: initialValue,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyBold),
      subtitle: Text(
        description,
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );
}
