/// FAB that opens a role-filtered quick-actions bottom sheet.
///
/// Rule 1 — under 200 lines.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

class PatientQuickActionsFab extends StatelessWidget {
  const PatientQuickActionsFab({
    super.key, required this.patient, required this.isDoctor,
  });
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      onPressed: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _QuickActionsSheet(patient: patient, isDoctor: isDoctor),
      ),
      child: const Icon(Icons.add_rounded),
    );
  }
}

class _QuickActionsSheet extends ConsumerWidget {
  const _QuickActionsSheet({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <_Action>[];

    if (!isDoctor) {
      actions.addAll([
        _Action(icon: Icons.calendar_today_rounded, label: 'Book Appointment',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.newAppointment, extra: patient);
            }),
        _Action(icon: Icons.payment_rounded, label: 'Collect Payment',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => CollectPaymentSheet(patient: patient),
              );
            }),
      ]);
    }

    actions.addAll([
      _Action(icon: Icons.note_add_rounded, label: 'Add Note',
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => AddNoteSheet(patientId: patient.id),
            );
          }),
      _Action(icon: Icons.attach_file_rounded, label: 'Add Document',
          onTap: () => _showDocumentSheet(context, ref)),
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
                  icon: a.icon, label: a.label, onTap: a.onTap,
                )),
          ],
        ),
      ),
    );
  }

  void _showDocumentSheet(BuildContext outerCtx, WidgetRef ref) {
    final nav = Navigator.of(outerCtx);
    showModalBottomSheet(
      context: outerCtx,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Document', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.p16),
              _docTile(Icons.camera_alt_rounded, 'Take Photo', () async {
                await _doUpload(ref, ctx, FileType.image);
                if (ctx.mounted) { Navigator.pop(ctx); nav.pop(); }
              }),
              _docTile(Icons.photo_library_rounded, 'Upload from Gallery', () async {
                await _doUpload(ref, ctx, FileType.image);
                if (ctx.mounted) { Navigator.pop(ctx); nav.pop(); }
              }),
              _docTile(Icons.folder_open_rounded, 'Browse Files', () async {
                await _doUpload(ref, ctx, FileType.custom,
                    allowed: ['pdf', 'png', 'jpg', 'jpeg']);
                if (ctx.mounted) { Navigator.pop(ctx); nav.pop(); }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doUpload(WidgetRef ref, BuildContext ctx, FileType type,
      {List<String>? allowed}) async {
    final result = await FilePicker.platform.pickFiles(
      type: type, allowedExtensions: allowed, allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!ctx.mounted) return;
    final uploadResult = await ref
        .read(patientDocumentsNotifierProvider(patient.id).notifier)
        .uploadDocument(fileName: file.name, filePath: file.path, fileBytes: file.bytes);
    if (!ctx.mounted) return;
    uploadResult.when(
      success: (_) => AppSnackbar.show(ctx,
          message: 'Document uploaded.', variant: AppSnackbarVariant.success),
      failure: (error) => AppSnackbar.show(ctx,
          message: 'Upload failed: ${error.message}', variant: AppSnackbarVariant.error),
    );
  }

  Widget _docTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
      onTap: onTap,
    );
  }
}

class _Action { const _Action({required this.icon, required this.label, required this.onTap}); final IconData icon; final String label; final VoidCallback onTap; }

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
      onTap: onTap,
    );
  }
}
