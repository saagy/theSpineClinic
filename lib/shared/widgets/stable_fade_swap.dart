import 'package:flutter/material.dart';

/// Fades a resolved field into the same leading position as its placeholder.
class StableFadeSwap extends StatelessWidget {
  const StableFadeSwap({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final Object stateKey;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (current, animation) =>
          FadeTransition(opacity: animation, child: current),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}
