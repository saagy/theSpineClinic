import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/form_page_body.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../../domain/service_catalog_item.dart';
import '../invoice_detail_providers.dart';
import 'refund_form_input.dart';
import 'refund_sections.dart';
import 'refund_summary_panel.dart';

const _t = AppStrings.invoiceDetail;

/// Reduces an invoice's value, cancels unused sessions and, when the patient
/// has paid more than the new value, records the money handed back.
class RefundForm extends ConsumerStatefulWidget {
  const RefundForm({
    super.key,
    required this.invoice,
    required this.ptBalance,
    required this.tractionBalance,
    required this.defaultBranch,
  });
  final InvoiceDetail invoice;

  /// The patient's unused sessions; only these can be cancelled.
  final int ptBalance;
  final int tractionBalance;
  final ClinicLocation defaultBranch;

  @override
  ConsumerState<RefundForm> createState() => _RefundFormState();
}

class _RefundFormState extends ConsumerState<RefundForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final RefundFormInput _input = RefundFormInput(
    invoice: widget.invoice,
    branch: widget.defaultBranch,
    balances: {
      ServiceType.ptSession: widget.ptBalance,
      ServiceType.tractionSession: widget.tractionBalance,
    },
  );
  bool _saving = false;
  bool _triedSave = false;
  bool _confirmingDiscard = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _input.addListener(_refresh);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _leave({bool saved = false}) => context.canPop()
      ? context.pop(saved)
      : context.go(AppRoutes.invoiceDetailLocation(widget.invoice.patientId, widget.invoice.id));

  Future<void> _cancel() async {
    if (_saving || _confirmingDiscard) return;
    if (_input.isPristine) return _leave();
    _confirmingDiscard = true;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.discardChanges,
        message: AppStrings.discardChangesMessage,
        confirmLabel: AppStrings.discard,
        cancelLabel: AppStrings.keepEditing,
      ),
    );
    _confirmingDiscard = false;
    if (mounted && discard == true) _leave();
  }

  Future<void> _save() async {
    setState(() => _triedSave = true);
    final RefundDraft draft = _input.draft();
    final bool valid = _form.currentState?.validate() ?? false;
    if (!valid || !draft.hasLines || (draft.paybackMinor > 0 && draft.method == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(invoiceActionControllerProvider.notifier)
        .run(InvoiceAction.refund(draft));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.exceptionOrNull;
    });
    if (!result.isSuccess) return;
    _leave(saved: true); // The invoice confirms the refund once it is back in view.
  }

  @override
  Widget build(BuildContext context) {
    final RefundDraft draft = _input.draft();
    final bool enabled = !_saving;
    void change(VoidCallback update) => setState(update);
    final sections = [
      RefundLinesSection(input: _input, enabled: enabled, showMissing: _triedSave, onChanged: change),
      RefundDetailsSection(
        input: _input,
        paybackMinor: draft.paybackMinor,
        enabled: enabled,
        showMissing: _triedSave,
        onChanged: change,
      ),
    ];
    final summary = RefundSummaryPanel(draft: draft);
    return PopScope(
      canPop: !_saving && _input.isPristine,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_t.refundTitle} · ${widget.invoice.summary.displayNumber}'),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.backTooltip,
            onPressed: _saving ? null : _cancel,
          ),
        ),
        body: FormPageBody(
          isSaving: _saving,
          saveLabel: _t.recordRefund,
          errorMessage: _error == null ? null : AppStrings.fromKey(_error!.userMessageKey),
          onSave: _saving ? null : _save,
          onCancel: _saving ? null : _cancel,
          aside: summary,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, section) in sections.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSizes.p24),
                  section,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
