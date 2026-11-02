import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Estimated activity, with no numeric completion claim or early success state.
class OperationProgressTrack extends StatefulWidget {
  const OperationProgressTrack({super.key});

  @override
  State<OperationProgressTrack> createState() => _OperationProgressTrackState();
}

class _OperationProgressTrackState extends State<OperationProgressTrack> {
  static const double _start = 0.08;
  static const double _ceiling = 0.94;
  final ValueNotifier<double> _progress = ValueNotifier(_start);
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Advance quickly at first, then approach the ceiling without reaching 100%.
      _progress.value = _start + (_ceiling - _start) * timer.tick / (timer.tick + 8);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ValueListenableBuilder<double>(
      valueListenable: _progress,
      builder: (context, progress, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: _start, end: progress),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: AppSizes.operationProgressHeight,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
  );
}
