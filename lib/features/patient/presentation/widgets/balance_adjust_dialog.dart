import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/balance_adjustment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';

const _t = AppStrings.balances;

/// Corrects a patient's PT and traction balances, with a required reason.
/// Pops `true` once saved.
class BalanceAdjustDialog extends ConsumerStatefulWidget {
  const BalanceAdjustDialog({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<BalanceAdjustDialog> createState() => _BalanceAdjustDialogState();
}

class _BalanceAdjustDialogState extends ConsumerState<BalanceAdjustDialog> {
  static const int _maxSessions = 1000;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _pt = TextEditingController(text: '${widget.patient.sessionBalance}');
  late final TextEditingController _traction = TextEditingController(
    text: '${widget.patient.tractionBalance}',
  );
  final TextEditingController _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pt.dispose();
    _traction.dispose();
    _reason.dispose();
    super.dispose();
  }

  int? _count(TextEditingController controller) => int.tryParse(controller.text.trim());

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final int pt = _count(_pt)!;
    final int traction = _count(_traction)!;
    if (pt == widget.patient.sessionBalance && traction == widget.patient.tractionBalance) {
      setState(() => _error = _t.noChange);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final Result<void> result = await ref
        .read(balanceAdjustmentControllerProvider.notifier)
        .adjust(
          patientId: widget.patient.id,
          expectedPt: widget.patient.sessionBalance,
          expectedTraction: widget.patient.tractionBalance,
          pt: pt,
          traction: traction,
          reason: _reason.text,
        );
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) => setState(() {
        _saving = false;
        _error = AppStrings.fromKey(error.userMessageKey);
      }),
    );
  }

  Widget _number(String label, int current, TextEditingController controller) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return LabeledFormField(
      label: '$label · ${_t.now(current)}',
      enabled: !_saving,
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        style: AppTextStyles.body.copyWith(color: colors.onSurface),
        decoration: appInputDecoration(context, enabled: !_saving),
        validator: (text) {
          final int? value = int.tryParse((text ?? '').trim());
          return value == null || value > _maxSessions ? _t.wholeNumber : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface.withAlpha(0),
        scrollable: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16))),
        insetPadding: const EdgeInsets.all(AppSizes.p16),
        titlePadding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, 0),
        contentPadding: const EdgeInsets.all(AppSizes.p24),
        actionsPadding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, AppSizes.p24),
        title: Text(_t.title, style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface)),
        content: SizedBox(
          width: AppSizes.reasonDialogWidth,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_t.help, style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSizes.p20),
                _number(_t.ptSessions, widget.patient.sessionBalance, _pt),
                const SizedBox(height: AppSizes.p16),
                _number(_t.tractionSessions, widget.patient.tractionBalance, _traction),
                const SizedBox(height: AppSizes.p16),
                LabeledFormField(
                  label: _t.reason,
                  enabled: !_saving,
                  child: TextFormField(
                    controller: _reason,
                    enabled: !_saving,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    style: AppTextStyles.body.copyWith(color: colors.onSurface),
                    decoration: appInputDecoration(context, enabled: !_saving, hintText: _t.reasonHint),
                    validator: (text) => (text ?? '').trim().isEmpty ? _t.reasonRequired : null,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSizes.p16),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: AppTextStyles.caption.copyWith(color: colors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(minimumSize: minimum),
            child: Text(_t.cancel, style: AppTextStyles.button),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: minimum,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saving) ...[
                  const SizedBox.square(
                    dimension: AppSizes.iconSmall,
                    child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin),
                  ),
                  const SizedBox(width: AppSizes.p8),
                ],
                Text(_t.save, style: AppTextStyles.button),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
