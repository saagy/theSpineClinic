import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class PaymentModeSelector extends StatelessWidget {
  const PaymentModeSelector({
    super.key,
    required this.isPartial,
    required this.onChanged,
    this.enabled = true,
  });

  final bool isPartial;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.partialPayment,
          style: AppTextStyles.captionMedium.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Opacity(
          opacity: enabled ? 1.0 : 0.6,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r999)),
            ),
            padding: const EdgeInsets.all(AppSizes.p4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                return Stack(
                  children: [
                    // Sliding capsule background
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      alignment: isPartial
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: width / 2 - 2,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppSizes.r999),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withAlpha(60),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Clickable Text labels
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: enabled ? () => onChanged(false) : null,
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: !isPartial
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                                child: const Text(AppStrings.paidInFullMode),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: enabled ? () => onChanged(true) : null,
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: isPartial
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                                child: const Text(AppStrings.partialPaymentMode),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
