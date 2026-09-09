import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Compact facts flow across wide sections, wrapping naturally on narrow screens.
class RecordFactGrid extends StatelessWidget {
  const RecordFactGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          (constraints.maxWidth / AppSizes.recordFactWidth / MediaQuery.textScalerOf(context).scale(1))
              .floor()
              .clamp(1, children.length.clamp(1, 4));
      final width = (constraints.maxWidth - AppSizes.p20 * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSizes.p20,
        runSpacing: AppSizes.p8,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}
