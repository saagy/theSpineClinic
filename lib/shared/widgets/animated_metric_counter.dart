import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A lightweight, performance-conscious rolling counter for dashboard metrics.
///
/// Smoothly interpolates from an initial or previous value to a target numeric
/// value over [duration] using [curve].
///
/// On Web ([kIsWeb]), the transition duration is set to zero for immediate rendering.
class AnimatedMetricCounter extends StatelessWidget {
  /// Creates an [AnimatedMetricCounter].
  const AnimatedMetricCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  /// The target numeric value to display.
  final num value;

  /// Optional prefix string (e.g., "$", "+").
  final String prefix;

  /// Optional suffix string (e.g., "%", " pts").
  final String suffix;

  /// Number of decimal places to format (0 for integer counts).
  final int decimalPlaces;

  /// Text style for the rendered value.
  final TextStyle? style;

  /// Duration of the rolling animation on mobile.
  final Duration duration;

  /// Animation curve for the counter roll.
  final Curve curve;

  String _formatNumber(num val) {
    final String formatted = decimalPlaces > 0
        ? val.toStringAsFixed(decimalPlaces)
        : val.round().toString();
    return '$prefix$formatted$suffix';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Text(
        _formatNumber(value),
        style: style ?? Theme.of(context).textTheme.headlineMedium,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          _formatNumber(animatedValue),
          style: style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
