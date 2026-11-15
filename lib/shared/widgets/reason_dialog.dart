import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';

/// Asks why a recorded change is being made. Returns the trimmed reason, or
/// null when the person keeps things as they are.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String label,
  required String hint,
  required String requiredMessage,
  required String confirmLabel,
  required String cancelLabel,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(
    title: title,
    message: message,
    label: label,
    hint: hint,
    requiredMessage: requiredMessage,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.label,
    required this.hint,
    required this.requiredMessage,
    required this.confirmLabel,
    required this.cancelLabel,
  });
  final String title;
  final String message;
  final String label;
  final String hint;
  final String requiredMessage;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  static const int _maxLength = 500;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() ?? false) Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface.withAlpha(0),
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)),
      ),
      insetPadding: const EdgeInsets.all(AppSizes.p16),
      titlePadding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, 0),
      contentPadding: const EdgeInsets.all(AppSizes.p24),
      actionsPadding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, AppSizes.p24),
      title: Text(widget.title, style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface)),
      content: SizedBox(
        width: AppSizes.reasonDialogWidth,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message, style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppSizes.p20),
              LabeledFormField(
                label: widget.label,
                child: TextFormField(
                  controller: _reason,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
                  style: AppTextStyles.body.copyWith(color: colors.onSurface),
                  decoration: appInputDecoration(context, enabled: true, hintText: widget.hint),
                  validator: (text) => (text ?? '').trim().isEmpty ? widget.requiredMessage : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: minimum),
          child: Text(widget.cancelLabel, style: AppTextStyles.button),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            minimumSize: minimum,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          ),
          child: Text(widget.confirmLabel, style: AppTextStyles.button),
        ),
      ],
    );
  }
}
