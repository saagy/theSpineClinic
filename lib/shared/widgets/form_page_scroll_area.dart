import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// The scrolling part of [FormPageBody]. With an [aside] (such as a live
/// summary) on a wide window, the form scrolls in its own column and the
/// aside stays in view beside it; otherwise the aside follows the form.
class FormPageScrollArea extends StatelessWidget {
  const FormPageScrollArea({
    super.key,
    required this.child,
    required this.maxWidth,
    required this.isSaving,
    this.aside,
    this.asideWidth = AppSizes.invoiceSummaryPanelWidth,
    this.asideBreakpoint = AppSizes.invoiceFormWideBreakpoint,
  });
  final Widget child;
  final double maxWidth;
  final bool isSaving;
  final Widget? aside;
  final double asideWidth;

  /// Content width from which the aside sits beside the form.
  final double asideBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      Widget guard(Widget content) => ExcludeFocus(
        excluding: isSaving,
        child: AbsorbPointer(absorbing: isSaving, child: content),
      );
      final double content = math.min(box.maxWidth - AppSizes.p32, maxWidth);
      final bool wide = aside != null &&
          content >= asideBreakpoint &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
      if (!wide) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: guard(
                SizedBox(
                  width: double.infinity,
                  child: aside == null
                      ? child
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [child, const SizedBox(height: AppSizes.p24), aside!],
                        ),
                ),
              ),
            ),
          ),
        );
      }
      // Each side keeps its half of the outer margin, so the pair stays
      // centered and the left margin still scrolls the form.
      final double gutter = (box.maxWidth - content) / 2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(gutter, AppSizes.p16, 0, AppSizes.p16),
              child: guard(child),
            ),
          ),
          const SizedBox(width: AppSizes.p24),
          SizedBox(
            width: asideWidth + gutter,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(0, AppSizes.p16, gutter, AppSizes.p16),
              child: guard(aside!),
            ),
          ),
        ],
      );
    },
  );
}
