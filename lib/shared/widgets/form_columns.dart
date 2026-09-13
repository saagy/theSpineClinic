import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Two related groups use available room without stretching inputs across a PC.
class FormColumns extends StatelessWidget {
  const FormColumns({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = AppSizes.desktopBreakpoint,
  });
  final Widget first;
  final Widget second;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint || MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            const SizedBox(height: AppSizes.p20),
            second,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSizes.p24),
          Expanded(child: second),
        ],
      );
    },
  );
}
