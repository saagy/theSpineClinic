import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A text widget that animates changes to [text] with a vertical rolling
/// ticker effect (old text slides up and fades out, new text slides up from
/// below and fades in). Supports optional dynamic bounded scaling via [minFontSize].
class RollingTickerText extends StatelessWidget {
  const RollingTickerText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.duration = const Duration(milliseconds: 260),
    this.minFontSize,
    this.stepGranularity = 0.5,
  });

  /// The text content to display and animate.
  final String text;

  /// Text style applied to the inner [Text] widget.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum lines before truncating.
  final int maxLines;

  /// Overflow behaviour.
  final TextOverflow overflow;

  /// Duration of the rolling transition.
  final Duration duration;

  /// Minimum font size floor when dynamically scaling text.
  final double? minFontSize;

  /// Step granularity for font size changes when scaling.
  final double stepGranularity;

  @override
  Widget build(BuildContext context) {
    final Duration effectiveDuration = kIsWeb ? Duration.zero : duration;

    final Widget textChild = minFontSize != null
        ? AutoSizeText(
            text,
            key: ValueKey<String>(text),
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            minFontSize: minFontSize!,
            stepGranularity: stepGranularity,
            overflow: overflow,
          )
        : Text(
            text,
            key: ValueKey<String>(text),
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );

    return AnimatedSwitcher(
      duration: effectiveDuration,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool isIncoming = (child.key as ValueKey<String>?)?.value == text;
        final Offset beginOffset =
            isIncoming ? const Offset(0.0, 0.65) : const Offset(0.0, -0.65);
        final Animation<Offset> offsetAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: textChild,
    );
  }
}
