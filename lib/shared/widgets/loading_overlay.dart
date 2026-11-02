import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'operation_feedback.dart';

/// Lightweight feedback for operations that still require blocking interaction.
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = AppStrings.working,
    this.escapeHatchDuration = const Duration(seconds: 15),
  });
  final bool isLoading;
  final Widget child;
  final String message;
  final Duration escapeHatchDuration;
  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  Timer? _escapeTimer;
  bool _showEscapeHatch = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _startTimer();
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    _escapeTimer?.cancel();
    _showEscapeHatch = false;
    if (widget.isLoading) _startTimer();
  }

  void _startTimer() {
    _escapeTimer?.cancel();
    _escapeTimer = Timer(widget.escapeHatchDuration, () {
      if (mounted) setState(() => _showEscapeHatch = true);
    });
  }

  @override
  void dispose() {
    _escapeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canLeave =
        ModalRoute.of(context)?.popDisposition != RoutePopDisposition.doNotPop;
    return Stack(
      children: [
        ExcludeFocus(excluding: widget.isLoading, child: widget.child),
        if (widget.isLoading) ...[
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: colors.scrim.withAlpha(77),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.operationOverlayMaxWidth,
                  ),
                  child: Material(
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.p20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: AppSizes.iconSmall,
                            child: CircularProgressIndicator(
                              strokeWidth: AppSizes.strokeWidthThin,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p12),
                          Flexible(
                            child: OperationFeedback(
                              message: _showEscapeHatch
                                  ? AppStrings.takingLonger
                                  : widget.message,
                              detail: _showEscapeHatch
                                  ? AppStrings.requestStillPending
                                  : null,
                              action: _showEscapeHatch && canLeave
                                  ? TextButton(
                                      onPressed: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go(AppRoutes.home);
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size.square(
                                          AppSizes.tappableMin,
                                        ),
                                      ),
                                      child: const Text(
                                        AppStrings.goBack,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
