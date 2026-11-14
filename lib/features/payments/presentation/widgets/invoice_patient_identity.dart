import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

const _t = AppStrings.invoiceDetail;

/// The patient's name and invoice facts. With [onOpen], the block is a link
/// to the patient, marked by a chevron after the name.
class InvoicePatientIdentity extends StatelessWidget {
  const InvoicePatientIdentity({super.key, required this.name, required this.details, this.onOpen});
  final String name;
  final String details;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: name,
            children: [
              if (onOpen != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSizes.p4),
                    child: Icon(
                      Icons.chevron_right,
                      size: AppSizes.iconDefault,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSizes.p2),
        Text(details, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
    if (onOpen == null) return content;
    return Semantics(
      button: true,
      hint: _t.openPatientPayments,
      child: Tooltip(
        message: _t.openPatientPayments,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
            child: content,
          ),
        ),
      ),
    );
  }
}
