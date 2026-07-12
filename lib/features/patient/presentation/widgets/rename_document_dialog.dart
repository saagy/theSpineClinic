import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Compact metadata-only document rename dialog.
class RenameDocumentDialog extends ConsumerStatefulWidget {
  const RenameDocumentDialog({super.key, required this.document});

  final PatientDocument document;

  @override
  ConsumerState<RenameDocumentDialog> createState() =>
      _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends ConsumerState<RenameDocumentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final String _extension;
  late final String _originalBaseName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _extension = p.extension(widget.document.fileName);
    _originalBaseName = _extension.isEmpty
        ? widget.document.fileName
        : p.basenameWithoutExtension(widget.document.fileName);
    _controller = TextEditingController(text: _originalBaseName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: _originalBaseName.length,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _newFileName => '${_controller.text.trim()}$_extension';

  bool get _canSave =>
      !_isSaving &&
      _controller.text.trim().isNotEmpty &&
      _newFileName != widget.document.fileName &&
      _newFileName.length <= 255;

  String? _validate(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppStrings.documentNameRequired;
    if ('$trimmed$_extension'.length > 255) {
      return AppStrings.documentNameTooLong;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_canSave || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final Result<PatientDocument> result = await ref
        .read(
          patientDocumentsNotifierProvider(widget.document.patientId).notifier,
        )
        .renameDocument(document: widget.document, fileName: _newFileName);
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      success: (_) => Navigator.of(context).pop(true),
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
    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface.withAlpha(0),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSizes.borderRadiusDialog,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      title: Text(
        AppStrings.renameDocument,
        style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
      ),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          labelText: AppStrings.documentName,
          enabled: !_isSaving,
          validator: _validate,
          onChanged: (_) => setState(() {}),
          suffixIcon: _extension.isEmpty
              ? null
              : Text(
                  _extension,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        0,
        AppSizes.p24,
        AppSizes.p24,
      ),
      actions: [
        AppButton(
          labelText: AppStrings.cancel,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          variant: AppButtonVariant.secondary,
          fullWidth: false,
        ),
        AppButton(
          labelText: AppStrings.rename,
          onPressed: _canSave ? _save : null,
          isLoading: _isSaving,
          shape: AppButtonShape.pill,
          fullWidth: false,
        ),
      ],
    );
  }
}
