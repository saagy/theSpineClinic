import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A wrapper that applies a snappy, tactile micro-scale dip and spring
/// (`1.0` -> `0.985` -> `1.0`) whenever [trigger] value changes.
class TactileScaleContainer extends StatefulWidget {
  const TactileScaleContainer({
    super.key,
    required this.trigger,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  /// The value to watch for changes. When this changes, the spring animation fires.
  final Object? trigger;

  /// The widget subtree to animate.
  final Widget child;

  /// Duration of the spring bounce cycle.
  final Duration duration;

  @override
  State<TactileScaleContainer> createState() => _TactileScaleContainerState();
}

class _TactileScaleContainerState extends State<TactileScaleContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.985)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.985, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(TactileScaleContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !kIsWeb) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
