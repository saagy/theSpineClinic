/// FAB that opens a role-filtered quick-actions bottom sheet.
///
/// Handles document uploads directly so the async work survives
/// bottom-sheet disposal.
///
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:file_picker/file_picker.dart';
import '../document_upload_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_refresh.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/quick_actions_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

class PatientQuickActionsFab extends ConsumerStatefulWidget {
  const PatientQuickActionsFab({
    super.key,
    required this.patient,
    required this.isDoctor,
    required this.canHandlePayments,
  });
  final Patient patient;
  final bool isDoctor;
  final bool canHandlePayments;

  @override
  ConsumerState<PatientQuickActionsFab> createState() => _PatientQuickActionsFabState();
}

class _PatientQuickActionsFabState extends ConsumerState<PatientQuickActionsFab> {
  Future<void> _onBookAppointment() async {
    Navigator.of(context, rootNavigator: true).pop();
    await context.push(AppRoutes.newAppointment, extra: widget.patient);
    if (!mounted) return;
    AppointmentRefresh.patientAndDashboards(ref, patientId: widget.patient.id);
  }

  void _onCollectPayment() {
    Navigator.of(context, rootNavigator: true).pop();
    AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.collectPayment,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) =>
          CollectPaymentSheet(patient: widget.patient, scrollController: scrollController),
    );
  }

  void _onAddNote() {
    Navigator.of(context, rootNavigator: true).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
      ),
      builder: (_) => AddNoteSheet(patientId: widget.patient.id),
    );
  }

  Future<void> _onAddDocument() async {
    Navigator.of(context, rootNavigator: true).pop();
    if (!ref.read(documentUploadControllerProvider(widget.patient.id)).canPick) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final uploaded = await ref
        .read(documentUploadControllerProvider(widget.patient.id).notifier)
        .uploadFiles(result.files);
    if (mounted && uploaded.isSuccess) {
      AppSnackbar.show(context, message: AppStrings.documentUploaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUploading = ref.watch(documentUploadControllerProvider(widget.patient.id)).isLoading;
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      onPressed: isUploading
          ? null
          : () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
              ),
              builder: (_) => QuickActionsSheet(
                isDoctor: widget.isDoctor,
                canHandlePayments: widget.canHandlePayments,
                onBookAppointment: _onBookAppointment,
                onCollectPayment: _onCollectPayment,
                onAddNote: _onAddNote,
                onAddDocument: _onAddDocument,
              ),
            ),
      child: isUploading
          ? SizedBox(
              width: AppSizes.iconDefault,
              height: AppSizes.iconDefault,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.borderWidth,
                color: cs.onPrimary,
              ),
            )
          : const Icon(Icons.add_rounded),
    );
  }
}
