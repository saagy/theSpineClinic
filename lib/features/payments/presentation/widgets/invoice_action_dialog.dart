import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/invoice_action.dart';
import '../invoice_detail_providers.dart';

/// Shared frame for the small invoice commands (payment, receipt correction,
/// cancel): a bounded form, an inline failure message, and a confirm button
/// that shows progress and cannot be pressed twice. Pops `true` once saved.
class InvoiceActionDialog extends ConsumerStatefulWidget {
  const InvoiceActionDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.buildAction,
    required this.child,
    this.help,
    this.dismissLabel = AppStrings.cancel,
    this.destructive = false,
  });
  final String title;
  final String? help;
  final String confirmLabel;

  /// Label of the button that closes the dialog without saving.
  final String dismissLabel;
  final bool destructive;
  final Widget child;

  /// Reads the form after validation passes; null keeps the dialog open.
  final InvoiceAction? Function() buildAction;

  @override
  ConsumerState<InvoiceActionDialog> createState() => _InvoiceActionDialogState();
}

class _InvoiceActionDialogState extends ConsumerState<InvoiceActionDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _saving = false;
  AppException? _error;

  Future<void> _submit() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final InvoiceAction? action = widget.buildAction();
    if (action == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(invoiceActionControllerProvider.notifier).run(action);
    if (!mounted) return;
    if (result.isSuccess) return Navigator.of(context).pop(true);
    setState(() {
      _saving = false;
      _error = result.exceptionOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface.withAlpha(0),
        scrollable: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)),
        ),
        insetPadding: const EdgeInsets.all(AppSizes.p16),
        titlePadding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, 0),
        contentPadding: const EdgeInsets.all(AppSizes.p24),
        actionsPadding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, AppSizes.p24),
        title: Text(
          widget.title,
          style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
        ),
        content: SizedBox(
          width: AppSizes.invoiceDialogWidth,
          child: Form(
            key: _form,
            child: AbsorbPointer(
              absorbing: _saving,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.help != null) ...[
                    Text(
                      widget.help!,
                      style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSizes.p20),
                  ],
                  widget.child,
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.p16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        AppStrings.fromKey(_error!.userMessageKey),
                        style: AppTextStyles.caption.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(minimumSize: minimum),
            child: Text(widget.dismissLabel, style: AppTextStyles.button),
          ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: minimum,
              backgroundColor: widget.destructive ? colors.error : null,
              foregroundColor: widget.destructive ? colors.onError : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saving) ...[
                  const SizedBox.square(
                    dimension: AppSizes.iconSmall,
                    child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin),
                  ),
                  const SizedBox(width: AppSizes.p8),
                ],
                Text(widget.confirmLabel, style: AppTextStyles.button),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
