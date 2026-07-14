/// Helper widgets for [ReceptionistTodayTab]: search field.
///
/// Extracted to keep the parent file under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Search field for the today tab.
class TodaySearchField extends StatelessWidget {
  const TodaySearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p8),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by patient name…',
          hintStyle: AppTextStyles.bodySecondary,
          prefixIcon: Icon(Icons.search_rounded,
              color: Theme.of(context).colorScheme.primary, size: AppSizes.iconDefault),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12, vertical: AppSizes.p8),
        ),
      ),
    );
  }
}
