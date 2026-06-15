/// Role-filtered quick-actions bottom sheet for the patient profile FAB.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Displays role-filtered quick actions: Book Appointment, Collect Payment,
/// Add Note, and Add Document.
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
    final actions = <_Action>[];

    if (!isDoctor) {
      actions.addAll([
        _Action(
          icon: Icons.calendar_today_rounded,
          label: 'Book Appointment',
          onTap: onBookAppointment,
        ),
        _Action(
          icon: Icons.payment_rounded,
          label: 'Collect Payment',
          onTap: onCollectPayment,
        ),
      ]);
    }

    actions.addAll([
      _Action(
        icon: Icons.note_add_rounded,
        label: 'Add Note',
        onTap: onAddNote,
      ),
      _Action(
        icon: Icons.attach_file_rounded,
        label: 'Add Document',
        onTap: onAddDocument,
      ),
    ]);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Actions', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSizes.p20),
            ...actions.map((a) => _ActionTile(
                  icon: a.icon,
                  label: a.label,
                  onTap: a.onTap,
                )),
          ],
        ),
      ),
    );
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      onTap: onTap,
    );
  }
}
