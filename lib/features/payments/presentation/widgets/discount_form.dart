import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/form_page_body.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../invoice_detail_providers.dart';
import 'discount_form_input.dart';
import 'invoice_discount_section.dart';
import 'refund_sections.dart';
import 'refund_summary_panel.dart';

const _d = AppStrings.invoiceDiscount;

/// Lowers an issued invoice without replacing it: the invoice keeps its
/// number and receipts, and the discount is recorded as its own document.
/// When the patient has paid more than the new value, the difference is
/// recorded as paid back.
class DiscountForm extends ConsumerStatefulWidget {
  const DiscountForm({super.key, required this.invoice, required this.defaultBranch});
  final InvoiceDetail invoice;
  final ClinicLocation defaultBranch;

  @override
  ConsumerState<DiscountForm> createState() => _DiscountFormState();
}

class _DiscountFormState extends ConsumerState<DiscountForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final DiscountFormInput _input = DiscountFormInput(
    invoice: widget.invoice,
    branch: widget.defaultBranch,
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
    final DiscountDraft draft = _input.draft();
    final bool valid = _form.currentState?.validate() ?? false;
    final bool fits = draft.hasDiscount && draft.discountMinor <= widget.invoice.valueMinor;
    if (!valid || !fits || (draft.paybackMinor > 0 && draft.method == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(invoiceActionControllerProvider.notifier)
        .run(InvoiceAction.discount(draft));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.exceptionOrNull;
    });
    if (!result.isSuccess) return;
    _leave(saved: true); // The invoice confirms the discount once it is back in view.
  }

  @override
  Widget build(BuildContext context) {
    final DiscountDraft draft = _input.draft();
    final bool enabled = !_saving;
    final colors = Theme.of(context).colorScheme;
    void change(VoidCallback update) => setState(update);
    return PopScope(
      canPop: !_saving && _input.isPristine,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_d.screenTitle(widget.invoice.summary.displayNumber)),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.backTooltip,
            onPressed: _saving ? null : _cancel,
          ),
        ),
        body: FormPageBody(
          isSaving: _saving,
          saveLabel: _d.record,
          errorMessage: _error == null ? null : AppStrings.fromKey(_error!.userMessageKey),
          onSave: _saving ? null : _save,
          onCancel: _saving ? null : _cancel,
          aside: DiscountSummaryPanel(draft: draft),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceDiscountSection(
                  input: _input,
                  baseMinor: widget.invoice.valueMinor,
                  enabled: enabled,
                  onChanged: change,
                  title: _d.sectionAmount,
                  description: _d.fieldsHelp(Money.format(widget.invoice.valueMinor)),
                  amountInvalid: _d.amountInvalid,
                  removable: false,
                ),
                if (_triedSave && !draft.hasDiscount && _input.discountValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p8),
                    child: Text(_d.empty, style: AppTextStyles.caption.copyWith(color: colors.error)),
                  ),
                const SizedBox(height: AppSizes.p24),
                RefundDetailsSection(
                  input: _input,
                  paybackMinor: draft.paybackMinor,
                  enabled: enabled,
                  showMissing: _triedSave,
                  onChanged: change,
                  title: _d.details,
                  paybackNone: _d.paybackNone,
                  reasonHint: _d.reasonHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
