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

enum DocumentAction { rename, delete }

/// Touch-sized overflow menu for rename and delete document actions.
class PatientDocumentActions extends ConsumerStatefulWidget {
  const PatientDocumentActions({super.key, required this.document});

  final PatientDocument document;

  static List<PopupMenuItem<DocumentAction>> buildMenuItems(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return [
      PopupMenuItem<DocumentAction>(
        value: DocumentAction.rename,
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: colors.onSurface, size: AppSizes.iconDefault),
            const SizedBox(width: AppSizes.p12),
            Text(AppStrings.rename, style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
          ],
        ),
      ),
      PopupMenuItem<DocumentAction>(
        value: DocumentAction.delete,
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: colors.error, size: AppSizes.iconDefault),
            const SizedBox(width: AppSizes.p12),
            Text(AppStrings.delete, style: AppTextStyles.bodyMedium.copyWith(color: colors.error)),
          ],
        ),
      ),
    ];
  }

  static Future<void> renameDocument(BuildContext context, PatientDocument document) async {
    final bool? renamed = await showDialog<bool>(
      context: context,
      builder: (_) => RenameDocumentDialog(document: document),
    );
    if (renamed == true && context.mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.documentRenamed,
        variant: AppSnackbarVariant.success,
      );
    }
  }

  static Future<void> deleteDocument(
    BuildContext context,
    WidgetRef ref,
    PatientDocument document,
  ) async {
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
    if (confirmed != true || !context.mounted) return;

    final Result<void> result = await ref
        .read(
          patientDocumentsNotifierProvider(document.patientId).notifier,
        )
        .deleteDocument(document);
    if (!context.mounted) return;
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

  static Future<void> showContextMenu({
    required BuildContext context,
    required WidgetRef ref,
    required PatientDocument document,
    required Offset globalPosition,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      overlay.localToGlobal(Offset.zero) & overlay.size,
    );

    final colors = Theme.of(context).colorScheme;
    final DocumentAction? selected = await showMenu<DocumentAction>(
      context: context,
      position: position,
      color: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSizes.borderRadiusInput,
      ),
      elevation: 2,
      items: buildMenuItems(context),
    );

    if (selected == null || !context.mounted) return;
    if (selected == DocumentAction.rename) {
      await renameDocument(context, document);
    } else if (selected == DocumentAction.delete) {
      await deleteDocument(context, ref, document);
    }
  }

  @override
  ConsumerState<PatientDocumentActions> createState() =>
      _PatientDocumentActionsState();
}

class _PatientDocumentActionsState
    extends ConsumerState<PatientDocumentActions> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      await PatientDocumentActions.deleteDocument(
        context,
        ref,
        widget.document,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
            : PopupMenuButton<DocumentAction>(
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
                onSelected: (DocumentAction action) {
                  if (action == DocumentAction.rename) {
                    PatientDocumentActions.renameDocument(context, widget.document);
                  } else {
                    _handleDelete();
                  }
                },
                itemBuilder: (_) => PatientDocumentActions.buildMenuItems(context),
              ),
      ),
    );
  }
}
