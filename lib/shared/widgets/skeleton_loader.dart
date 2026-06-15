/// Material 3 skeleton-placeholder primitives with a subtle shimmer.
///
/// Compose [SkeletonBox], [SkeletonCircle], and [SkeletonCard] to build
/// screen-specific loading shells that match the real content layout.
///
/// Every skeleton surface reads its colour from the active theme so it
/// respects light / dark mode without hardcoded hex values.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Primitives ────────────────────────────────────────────────────────

/// A rounded rectangle whose colour shimmers between two theme surface tones.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
  });
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color highlight =
        Theme.of(context).colorScheme.surfaceContainerHigh;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate().shimmer(duration: 1200.ms, color: highlight);
  }
}

/// A circle skeleton (avatar placeholder).
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.radius = 24});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color highlight =
        Theme.of(context).colorScheme.surfaceContainerHigh;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: base,
        shape: BoxShape.circle,
      ),
    ).animate().shimmer(duration: 1200.ms, color: highlight);
  }
}

// ── Composed patterns ─────────────────────────────────────────────────

/// A skeleton card matching the app card style (rounded rect, soft shadow,
/// 16 px padding).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// A list-tile skeleton: circle leading + two text lines.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SkeletonCircle(radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [count] skeleton list tiles inside a padded column — useful as
/// a direct replacement for a loading spinner in list views.
class SkeletonTileList extends StatelessWidget {
  const SkeletonTileList({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(count, (_) => const SkeletonListTile()),
      ),
    );
  }
}
