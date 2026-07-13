import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

abstract final class AppAdaptiveModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    final bool wide =
        MediaQuery.sizeOf(context).width >= AppSizes.adaptiveModalBreakpoint;
    return showDialog<T>(
      context: context,
      builder: (_) => wide
          ? Dialog(
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.adaptiveDialogMaxWidth,
                  maxHeight: AppSizes.adaptiveDialogMaxHeight,
                ),
                child: child,
              ),
            )
          : Dialog.fullscreen(child: child),
    );
  }
}
