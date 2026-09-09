import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({super.key, required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: PatientMonogramBadge(name: patient.fullName, size: AppSizes.patientHeaderAvatarSize),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName, style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppSizes.p4),
                  Text(patient.clinic.displayLabel, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class WorkspaceTabs extends ConsumerWidget {
  const WorkspaceTabs({super.key, required this.patientId, required this.labels});
  final String patientId;
  final List<String> labels;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(patientActiveTabProvider(patientId));
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Builder(
              builder: (tabContext) => Semantics(
                selected: i == selected,
                child: Container(
                  margin: const EdgeInsets.only(right: AppSizes.p20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: AppSizes.borderWidthFocused,
                        color: i == selected ? colors.primary : colors.surface.withAlpha(0),
                      ),
                    ),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                      foregroundColor: i == selected ? colors.onSurface : colors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12, horizontal: AppSizes.p4),
                    ),
                    onPressed: () {
                      ref.read(patientActiveTabProvider(patientId).notifier).setTab(i);
                      Scrollable.ensureVisible(tabContext, alignment: 0.5);
                    },
                    child: Text(
                      labels[i],
                      style: i == selected ? AppTextStyles.bodyBold : AppTextStyles.body,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
