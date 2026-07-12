import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/rename_document_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

enum _DocumentAction { rename, delete }

/// Touch-sized overflow menu for rename and delete document actions.
class PatientDocumentActions extends ConsumerStatefulWidget {
  const PatientDocumentActions({super.key, required this.document});

  final PatientDocument document;

  @override
  ConsumerState<PatientDocumentActions> createState() =>
      _PatientDocumentActionsState();
}

class _PatientDocumentActionsState
    extends ConsumerState<PatientDocumentActions> {
  bool _isDeleting = false;

  Future<void> _rename() async {
    final bool? renamed = await showDialog<bool>(
      context: context,
      builder: (_) => RenameDocumentDialog(document: widget.document),
    );
    if (renamed == true && mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.documentRenamed,
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deleteDocumentTitle,
        message: AppStrings.confirmDeleteDocument,
        confirmLabel: AppStrings.delete,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final Result<void> result = await ref
        .read(
          patientDocumentsNotifierProvider(widget.document.patientId).notifier,
        )
        .deleteDocument(widget.document);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.documentDeleted,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppSizes.tappableMin,
      child: Material(
        color: colors.surface,
        shape: const CircleBorder(),
        child: _isDeleting
            ? Padding(
                padding: const EdgeInsets.all(AppSizes.p12),
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeWidthThin,
                  color: colors.error,
                ),
              )
            : PopupMenuButton<_DocumentAction>(
                tooltip: AppStrings.moreActions,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.onSurfaceVariant,
                  size: AppSizes.iconDefault,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSizes.borderRadiusInput,
                ),
                color: colors.surface,
                onSelected: (_DocumentAction action) {
                  if (action == _DocumentAction.rename) {
                    _rename();
                  } else {
                    _delete();
                  }
                },
                itemBuilder: (_) => [
                  _menuItem(
                    action: _DocumentAction.rename,
                    icon: Icons.edit_outlined,
                    label: AppStrings.rename,
                    color: colors.onSurface,
                  ),
                  _menuItem(
                    action: _DocumentAction.delete,
                    icon: Icons.delete_outline_rounded,
                    label: AppStrings.delete,
                    color: colors.error,
                  ),
                ],
              ),
      ),
    );
  }

  PopupMenuItem<_DocumentAction> _menuItem({
    required _DocumentAction action,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<_DocumentAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, color: color, size: AppSizes.iconDefault),
          const SizedBox(width: AppSizes.p12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
