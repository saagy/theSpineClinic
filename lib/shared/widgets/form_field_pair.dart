import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Related fields share a row only when width and text scale permit it.
class FormFieldPair extends StatelessWidget {
  const FormFieldPair({super.key, required this.first, this.second});
  final Widget first;
  final Widget? second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final bool wide =
          box.maxWidth >= AppSizes.formPairBreakpoint &&
          MediaQuery.textScalerOf(context).scale(1) <=
              AppSizes.formPairMaxTextScale;
      // One Flex retains field state, focus and selection across resizing.
      return Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: wide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          Flexible(flex: wide ? 1 : 0, fit: FlexFit.tight, child: first),
          if (second != null) ...[
            SizedBox(
              width: wide ? AppSizes.p20 : null,
              height: wide ? null : AppSizes.p20,
            ),
            Flexible(flex: wide ? 1 : 0, fit: FlexFit.tight, child: second!),
          ],
        ],
      );
    },
  );
}
