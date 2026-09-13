import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// One surface for a document or form; its internal sections remain flat.
class RecordSurface extends StatelessWidget {
  const RecordSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(AppSizes.r12),
    ),
    child: Padding(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint
            ? AppSizes.p24
            : AppSizes.p16,
      ),
      child: child,
    ),
  );
}
