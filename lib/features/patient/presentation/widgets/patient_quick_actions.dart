/// FAB that opens a role-filtered quick-actions bottom sheet.
///
/// Handles document uploads directly so the async work survives
/// bottom-sheet disposal.
///
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
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
  });
  final Patient patient;
  final bool isDoctor;

  @override
  ConsumerState<PatientQuickActionsFab> createState() =>
      _PatientQuickActionsFabState();
}

class _PatientQuickActionsFabState
    extends ConsumerState<PatientQuickActionsFab> {
  bool _isUploading = false;

  void _onBookAppointment() {
    Navigator.of(context, rootNavigator: true).pop();
    context.push(AppRoutes.newAppointment, extra: widget.patient);
  }

  void _onCollectPayment() {
    Navigator.of(context, rootNavigator: true).pop();
    AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.collectPayment,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => CollectPaymentSheet(
        patient: widget.patient,
        scrollController: scrollController,
      ),
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

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    if (!mounted) return;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      AppSnackbar.show(
        context,
        message: AppStrings.fromKey('error_doc_file_too_large'),
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final Result<PatientDocument> uploadResult = await ref
          .read(patientDocumentsNotifierProvider(widget.patient.id).notifier)
          .uploadDocument(fileName: file.name, fileBytes: bytes);
      if (!mounted) return;
      uploadResult.when(
        success: (_) => AppSnackbar.show(
          context,
          message: AppStrings.documentUploaded,
          variant: AppSnackbarVariant.success,
        ),
        failure: (AppException error) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      onPressed: _isUploading
          ? null
          : () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.r16),
                ),
              ),
              builder: (_) => QuickActionsSheet(
                isDoctor: widget.isDoctor,
                onBookAppointment: _onBookAppointment,
                onCollectPayment: _onCollectPayment,
                onAddNote: _onAddNote,
                onAddDocument: _onAddDocument,
              ),
            ),
      child: _isUploading
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
