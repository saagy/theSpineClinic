import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Labeled pane container for the wide split-view booking workboard.
class BookingWorkboardPane extends StatelessWidget {
  const BookingWorkboardPane({
    super.key,
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.sectionCount(title, count),
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSizes.p12),
        Expanded(child: child),
      ],
    );
  }
}
