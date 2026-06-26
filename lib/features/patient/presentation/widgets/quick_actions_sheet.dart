/// Role-filtered quick-actions bottom sheet for the patient profile FAB.
///
/// Rule 13 — each action is a distinct r16 container.
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({
    super.key,
    required this.isDoctor,
    required this.onBookAppointment,
    required this.onCollectPayment,
    required this.onAddNote,
    required this.onAddDocument,
  });
  final bool isDoctor;
  final VoidCallback onBookAppointment;
  final VoidCallback onCollectPayment;
  final VoidCallback onAddNote;
  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actions = <_Action>[];

    if (!isDoctor) {
      actions.addAll([
        _Action(
            icon: Icons.calendar_today_rounded,
            label: AppStrings.bookAppointment,
            onTap: onBookAppointment),
        _Action(
            icon: Icons.payment_rounded,
            label: AppStrings.collectPayment,
            onTap: onCollectPayment),
      ]);
    }

    actions.addAll([
      _Action(
          icon: Icons.note_add_rounded,
          label: AppStrings.addNote,
          onTap: onAddNote),
      _Action(
          icon: Icons.attach_file_rounded,
          label: AppStrings.addDocument,
          onTap: onAddDocument),
    ]);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.p2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(AppStrings.quickActions, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSizes.p20),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: _ActionTile(
                    icon: a.icon,
                    label: a.label,
                    onTap: a.onTap,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Action {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: AppSizes.iconDefault),
              const SizedBox(width: AppSizes.p16),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
