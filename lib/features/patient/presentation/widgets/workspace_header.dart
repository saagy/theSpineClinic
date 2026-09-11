import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({super.key, required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhone = patient.phoneNumber.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: PatientMonogramBadge(name: patient.fullName, size: AppSizes.p40),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.fullName,
                  style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.p4),
                Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(AppSizes.r6),
                      ),
                      child: Text(
                        patient.clinic.displayLabel,
                        style: AppTextStyles.captionBold.copyWith(color: cs.onSecondaryContainer),
                      ),
                    ),
                    if (hasPhone)
                      Material(
                        color: cs.surfaceContainerHigh.withAlpha(120),
                        borderRadius: BorderRadius.circular(AppSizes.r6),
                        child: InkWell(
                          onTap: () => PatientPhoneOptionsSheet.show(context, patient.phoneNumber),
                          borderRadius: BorderRadius.circular(AppSizes.r6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.phone, size: 12, color: cs.primary),
                                const SizedBox(width: AppSizes.p4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    Formatters.formatPhone(patient.phoneNumber),
                                    style: AppTextStyles.captionBold.copyWith(color: cs.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p2),
                                Icon(LucideIcons.chevron_down, size: 12, color: cs.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceTabsDelegate extends SliverPersistentHeaderDelegate {
  WorkspaceTabsDelegate({required this.child, required this.backgroundColor});
  final Widget child;
  final Color backgroundColor;

  @override
  double get minExtent => AppSizes.p48;
  @override
  double get maxExtent => AppSizes.p48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(child: child),
          const Divider(height: AppSizes.borderWidth),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant WorkspaceTabsDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.backgroundColor != backgroundColor;
  }
}
