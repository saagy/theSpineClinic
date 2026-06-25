/// FAB that opens a role-filtered quick-actions bottom sheet.
///
/// The FAB itself is a ConsumerStatefulWidget so file-picking and upload
/// survive sheet dismissal — the sheet merely signals which action was picked.
///
/// Rule 1 — under 200 lines.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
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
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// FAB that surfaces a role-filtered quick-actions menu.
///
/// Handles document uploads directly so the async work survives bottom-sheet
/// disposal (the sheet's context is gone the moment [Navigator.pop] runs).
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

class _PatientQuickActionsFabState extends ConsumerState<PatientQuickActionsFab> {
  bool _isUploading = false;

  // ── Sheet action callbacks ──────────────────────────────────────────

  void _onBookAppointment() {
    Navigator.of(context, rootNavigator: true).pop();
    context.push(AppRoutes.newAppointment, extra: widget.patient);
  }

  void _onCollectPayment() {
    Navigator.of(context, rootNavigator: true).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CollectPaymentSheet(patient: widget.patient),
    );
  }

  void _onAddNote() {
    Navigator.of(context, rootNavigator: true).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteSheet(patientId: widget.patient.id),
    );
  }

  /// Dismisses the quick-actions sheet first, then triggers the native file
  /// picker. The upload runs inside this stateful widget so [ref] and [mounted]
  /// remain valid even after the sheet is gone.
  ///
  /// `try`/`finally` with `mounted` guards ensure the FAB always
  /// re-enables, even if the future is interrupted or the widget is
  /// disposed mid-upload. Upload outcomes flow through [AppSnackbar]
  /// so transient failures never replace the documents list (the
  /// list AsyncNotifier is intentionally NOT mutated here).
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
          .uploadDocument(
            fileName: file.name,
            fileBytes: bytes,
          );
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

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor:
          _isUploading ? AppColors.primary.withAlpha(180) : AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      onPressed: _isUploading
          ? null
          : () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          ? const SizedBox(
              width: AppSizes.iconDefault,
              height: AppSizes.iconDefault,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.textOnPrimary,
              ),
            )
          : const Icon(Icons.add_rounded),
    );
  }
}
