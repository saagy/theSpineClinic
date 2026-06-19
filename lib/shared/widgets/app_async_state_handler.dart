/// Unified async-state handler that renders skeleton → error → empty → data
/// states from a single [AsyncValue<T>] source.
///
/// Eliminates the per-screen duplication of `.when()` with inconsistent
/// error formatting and non-scrollable error views.
///
/// Three states:
/// - **Loading**: skeleton tiles.
/// - **Error**: scrollable [ErrorView] with pull-to-refresh retry.
/// - **Data**: [onData] callback renders the real content (including empty).
///
/// The 10-second timeout in [SupabaseService.guardQuery] provides the
/// escape mechanism — no intermediate escape hatch is needed.
///
/// Rule 1 — under 200 lines.
/// Rule 16 — zero hardcoded colours, all via theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Renders loading / error / data from an [AsyncValue].
///
/// Loading shows skeleton tiles. Error is always scrollable with
/// pull-to-refresh. The `onData` callback receives the unwrapped data
/// and should handle the empty case itself.
class AppAsyncStateHandler<T> extends StatelessWidget {
  /// Creates an [AppAsyncStateHandler].
  const AppAsyncStateHandler({
    super.key,
    required this.asyncValue,
    required this.onData,
    this.onRetry,
    this.emptyMessage = 'No items found',
    this.emptyIcon = Icons.inbox_rounded,
    this.skeletonCount = 5,
  });

  /// The Riverpod async value driving the three states.
  final AsyncValue<T> asyncValue;

  /// Builds the data widget. Called only when [asyncValue] has data.
  final Widget Function(T data) onData;

  /// Called when the user taps Retry or pulls to refresh on the error state.
  final VoidCallback? onRetry;

  /// Message shown in the empty state (unused by this widget; forwarded for
  /// callers that use it in [onData]).
  final String emptyMessage;

  /// Icon shown in the empty state.
  final IconData emptyIcon;

  /// Number of skeleton tiles shown during loading.
  final int skeletonCount;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<T> value = asyncValue;

    return value.when(
      loading: () => SkeletonTileList(count: skeletonCount),
      error: (e, s) => _buildError(context, e),
      data: onData,
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final AppException ex = error is AppException
        ? error
        : UnknownException(message: '$error');

    return onRetry != null
        ? RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async => onRetry?.call(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: ErrorView(exception: ex, onRetry: onRetry),
                ),
              ],
            ),
          )
        : ErrorView(exception: ex);
  }
}
