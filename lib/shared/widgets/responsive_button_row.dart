/// A row of buttons that automatically stacks vertically when the
/// available width is below a breakpoint.
///
/// Pill-shaped buttons add noticeable horizontal padding. On narrow
/// phones, two `Expanded` pill buttons placed side-by-side can either
/// overflow or force text/icon misalignment. This widget avoids both
/// outcomes: at widths at or above [breakpoint], children are laid out
/// horizontally with [Expanded] equal-width shares and the supplied
/// [gap] separator; below the breakpoint, children are stacked
/// vertically, each taking the full available width.
///
/// Rule 1 — under 200 lines.
/// Rule 11 — mobile-touch first; avoids cramped horizontal hits.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// A layout primitive for grouping buttons that gracefully fall back to
/// a vertical stack on narrow screens.
class ResponsiveButtonRow extends StatelessWidget {
  /// Creates a [ResponsiveButtonRow].
  ///
  /// [children] must contain 2 or more widgets intended for equal-share
  /// horizontal layout. Below [breakpoint] (in logical pixels) the
  /// layout switches to vertical stacking with the same separator gap.
  const ResponsiveButtonRow({
    super.key,
    required this.children,
    this.breakpoint = 480.0,
    this.gap = AppSizes.p12,
  });

  /// Buttons that should share the row equally at wide widths.
  final List<Widget> children;

  /// Logical-pixel width at which the layout switches from horizontal
  /// to vertical. Defaults to 480 (small phone threshold).
  final double breakpoint;

  /// Horizontal/vertical separator between children.
  final double gap;

  @override
  Widget build(BuildContext context) {
    assert(children.length >= 2,
        'ResponsiveButtonRow expects at least two children.');
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stackVertically = constraints.maxWidth < breakpoint;
        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withVerticalGaps(),
          );
        }
        return Row(
          children: _withHorizontalGaps(),
        );
      },
    );
  }

  List<Widget> _withHorizontalGaps() {
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(width: gap));
      out.add(Expanded(child: children[i]));
    }
    return out;
  }

  List<Widget> _withVerticalGaps() {
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return out;
  }
}
