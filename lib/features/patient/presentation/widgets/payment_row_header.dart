/// Header row for payment cards (Title, Amount, Right-aligned Status Badge, Full-width Metadata).
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — Theme colorScheme and AppTextStyles tokens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_actions_menu.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

/// Header section of a payment card.
class PaymentRowHeader extends StatelessWidget {
  const PaymentRowHeader({
    super.key,
    required this.payment,
    required this.recordedByAsync,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentRecord payment;
  final AsyncValue<Staff>? recordedByAsync;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                payment.reason,
                style: AppTextStyles.cardTitle.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  payment.amount.toCurrencyString(),
                  style: AppTextStyles.numberLarge.copyWith(
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: AppSizes.p4),
                  PaymentActionsMenu(
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p6),
        _buildMetadataRow(cs),
      ],
    );
  }

  Widget _buildMetadataRow(ColorScheme cs) {
    final dateStr = payment.recordedAt.toDateTimeString();
    final staffText = recordedByAsync?.when(
          data: (staff) => staff.fullName,
          loading: () => null,
          error: (_, __) => null,
        ) ??
        '';

    final text = staffText.isNotEmpty
        ? '$dateStr  •  ${AppStrings.recordedBy} $staffText'
        : dateStr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!payment.hasOutstandingDue) ...[
          const SizedBox(width: AppSizes.p8),
          _buildFullyPaidBadge(cs),
        ],
      ],
    );
  }

  Widget _buildFullyPaidBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(AppSizes.r6),
      ),
      child: Text(
        AppStrings.paidInFull,
        style: AppTextStyles.captionBold.copyWith(
          color: cs.primary,
        ),
      ),
    );
  }
}
