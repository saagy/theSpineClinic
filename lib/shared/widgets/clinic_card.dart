/// White card container with soft shadow and generous padding.
///
/// The standard surface container for all content sections across
/// the app. No hard borders — uses a barely-visible shadow to lift
/// off the pure white background. Matches the Medics UI Kit style.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// A shadow-elevated white card with generous rounded corners.
class ClinicCard extends StatelessWidget {
  /// Creates a [ClinicCard].
  const ClinicCard({
    super.key,
    this.title,
    this.trailing,
    this.padding,
    this.margin,
    this.child,
  });

  /// Optional header title displayed at the top-left of the card.
  final String? title;

  /// Optional widget displayed at the top-right (e.g. action link, icon).
  final Widget? trailing;

  /// Override the default internal padding. Defaults to [AppSizes.paddingCard].
  final EdgeInsetsGeometry? padding;

  /// Optional external margin. Defaults to zero.
  final EdgeInsetsGeometry? margin;

  /// The card body content.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusCard,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.p20,
                AppSizes.p20,
                AppSizes.p20,
                child != null ? AppSizes.p4 : AppSizes.p20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (child != null)
            Padding(
              padding: padding ??
                  EdgeInsets.only(
                    left: AppSizes.p20,
                    right: AppSizes.p20,
                    bottom: AppSizes.p20,
                    top: (title != null || trailing != null)
                        ? 0
                        : AppSizes.p20,
                  ),
              child: child!,
            ),
        ],
      ),
    );
  }
}
