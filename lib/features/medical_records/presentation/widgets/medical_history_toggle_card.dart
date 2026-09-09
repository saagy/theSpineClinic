import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';

/// A compact condition row; dependent inputs appear directly below its switch.
class MedicalHistoryToggleCard extends StatelessWidget {
  const MedicalHistoryToggleCard({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.expandedChild,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedChild;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: onChanged,
          title: Text(title, style: AppTextStyles.bodyBold),
        ),
        RecordTransition(
          child: expandedChild == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: expandedChild,
                ),
        ),
      ],
    ),
  );
}
