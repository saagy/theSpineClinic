import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';

const _t = AppStrings.invoiceDetail;

/// What happened to the money on a paid invoice that is being cancelled.
enum PaidInvoiceCancel { enteredByMistake, givenBack }

/// Asks one plain question before cancelling a paid invoice, so staff never
/// need to know the order of steps: was the money given back or not?
class InvoiceCancelPaidDialog extends StatelessWidget {
  const InvoiceCancelPaidDialog({super.key, required this.receivedMinor});
  final int receivedMinor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
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
        _t.voidInvoice,
        style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: AppSizes.invoiceDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t.paidCancelQuestion(Money.format(receivedMinor)),
              style: AppTextStyles.body.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSizes.p16),
            _Choice(
              icon: Icons.block,
              title: _t.paidCancelMistake,
              detail: _t.paidCancelMistakeHelp,
              onTap: () => Navigator.of(context).pop(PaidInvoiceCancel.enteredByMistake),
            ),
            const SizedBox(height: AppSizes.p8),
            _Choice(
              icon: Icons.undo,
              title: _t.paidCancelGivenBack,
              detail: _t.paidCancelGivenBackHelp,
              onTap: () => Navigator.of(context).pop(PaidInvoiceCancel.givenBack),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
          ),
          child: Text(_t.keepIt, style: AppTextStyles.button),
        ),
      ],
    );
  }
}

/// One answer, shown as a full-width button with its consequence below.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.r12),
      side: BorderSide(color: colors.outlineVariant),
    );
    return Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: AppSizes.iconDefault, color: colors.primary),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface)),
                      const SizedBox(height: AppSizes.p4),
                      Text(
                        detail,
                        style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: AppSizes.iconDefault,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
