/// Custom loading overlay widget matching the Spine Clinic styling tokens.
///
/// Wraps a screen or content widget to display a full-screen, touch-blocking
/// modal loading indicator when asynchronous operations are in progress.
/// Includes an escape hatch if the loading state persists.
///
/// All colours are resolved from [Theme.of(context).colorScheme] for
/// automatic dark-mode compatibility.
///
/// Rule 1 — keep files under 200 lines.
/// Rule 16 — zero hardcoded colours, all via theme.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

/// A full-screen blocking overlay spinner styled with Spine Clinic design tokens.
class LoadingOverlay extends StatefulWidget {
  /// Creates a [LoadingOverlay].
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  /// Whether the loading overlay spinner is visible.
  final bool isLoading;

  /// The widget content rendered beneath the overlay.
  final Widget child;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  Timer? _escapeTimer;
  bool _showEscapeHatch = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    _escapeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showEscapeHatch = true);
      }
    });
  }

  void _stopTimer() {
    _escapeTimer?.cancel();
    _escapeTimer = null;
    _showEscapeHatch = false;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AbsorbPointer(
            absorbing: true,
            child: Container(
              color: cs.scrim.withAlpha(77), // ~30 % opacity scrim
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                    if (_showEscapeHatch) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Taking longer than usual...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Check your connection or cancel the request.',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: cs.error.withAlpha(25),
                                foregroundColor: cs.error,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text(
                                'Cancel & Go Back',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
