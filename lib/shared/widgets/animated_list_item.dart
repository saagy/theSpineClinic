import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A wrapper widget that plays a subtle slide-up + fade-in animation
/// only once per list item. Used to prevent repetitive animation triggers
/// during list scrolling, resulting in a cleaner and faster UI.
class AnimatedListItem extends StatefulWidget {
  /// The item widget to animate.
  final Widget child;

  /// The index of the item in the list.
  final int index;

  /// The set of indices that have already animated.
  /// This must be stored in the parent widget's state and cleared
  /// when filters or search queries change to allow re-animation.
  final Set<int> animatedIndices;

  /// The duration of the slide-up and fade-in animation.
  final Duration duration;

  /// Creates an [AnimatedListItem].
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    required this.animatedIndices,
    this.duration = const Duration(milliseconds: 150), // 150ms feels premium and smooth
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> {
  late final bool _shouldAnimate;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !widget.animatedIndices.contains(widget.index);
    if (_shouldAnimate) {
      widget.animatedIndices.add(widget.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) {
      return widget.child;
    }

    return widget.child
        .animate()
        .fadeIn(duration: widget.duration)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: widget.duration,
          curve: Curves.easeOutQuad,
        );
  }
}
