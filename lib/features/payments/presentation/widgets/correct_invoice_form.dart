import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/form_page_body.dart';
import '../../../auth/domain/staff.dart';
import '../../../patient/domain/patient.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../../domain/invoice_draft.dart';
import '../../domain/service_catalog_item.dart';
import '../invoice_detail_providers.dart';
import 'correction_sections.dart';
import 'invoice_details_section.dart';
import 'invoice_form_input.dart';
import 'invoice_line_editor.dart';
import 'invoice_lines_section.dart';
import 'invoice_money_sections.dart';
import 'invoice_summary_panel.dart';
import 'service_picker_sheet.dart';

const _t = AppStrings.invoiceDetail;

/// Replaces an invoice: the form starts from the original's details, and
/// saving voids the original and issues the corrected copy in one step.
class CorrectInvoiceForm extends ConsumerStatefulWidget {
  const CorrectInvoiceForm({
    super.key,
    required this.invoice,
    required this.patient,
    required this.services,
    required this.doctors,
  });
  final InvoiceDetail invoice;
  final Patient patient;

  /// Active services only.
  final List<ServiceCatalogItem> services;
  final List<Staff> doctors;

  @override
  ConsumerState<CorrectInvoiceForm> createState() => _CorrectInvoiceFormState();
}

class _CorrectInvoiceFormState extends ConsumerState<CorrectInvoiceForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();
  late final InvoiceDetail _invoice = widget.invoice;
  late final InvoiceFormInput _input;
  late final List<String> _dropped;
  late final String _initial;
  bool _saving = false;
  bool _triedSave = false;
  bool _confirmingDiscard = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final prefill = prefillCorrection(_invoice, widget.services, widget.doctors);
    _input = prefill.input;
    _dropped = prefill.dropped;
    _initial = _fingerprint;
    _input.addListener(_refresh);
    _reason.addListener(_refresh);
  }

  @override
  void didUpdateWidget(CorrectInvoiceForm old) {
    super.didUpdateWidget(old);
    if (!identical(old.services, widget.services)) _input.syncCatalog(widget.services);
  }

  @override
  void dispose() {
    _input.dispose();
    _reason.dispose();
    super.dispose();
  }

  String get _fingerprint => '${_input.draft(_invoice.patientId).toPayload()}';
  bool get _pristine => _reason.text.trim().isEmpty && _fingerprint == _initial;

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _leave() => context.canPop()
      ? context.pop()
      : context.go(AppRoutes.invoiceDetailLocation(_invoice.patientId, _invoice.id));

  Future<void> _addLine() async {
    final ServiceCatalogItem? service = await ServicePickerSheet.show(context, widget.services);
    if (service == null || !mounted) return;
    final List<Staff> previous = _input.lines.reversed
        .firstWhere((line) => line.doctors.isNotEmpty, orElse: () => InvoiceLineInput(key: -1, service: service))
        .doctors;
    setState(() => _input.lines.add(InvoiceLineInput(
      key: _input.nextKey(),
      service: service,
      doctors: service.creditsDoctors ? previous : const [],
    )));
  }

  Future<void> _cancel() async {
    if (_saving || _confirmingDiscard) return;
    if (_pristine) return _leave();
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
    final InvoiceDraft draft = _input.draft(_invoice.patientId);
    final bool valid = _form.currentState?.validate() ?? false;
    if (!valid || _input.lines.isEmpty || draft.totalMinor < _invoice.receivedMinor) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(invoiceActionControllerProvider.notifier)
        .run(InvoiceAction.correctInvoice(_invoice, draft, _reason.text));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.exceptionOrNull;
    });
    final String? replacement = result.dataOrNull;
    if (replacement == null) return;
    // Land on the corrected invoice in place of the voided original; it
    // names the invoice it corrects, which confirms the change.
    final router = GoRouter.of(context);
    final String location = AppRoutes.invoiceDetailLocation(_invoice.patientId, replacement);
    if (!router.canPop()) return router.go(location);
    router.pop();
    router.pushReplacement(location);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !_saving;
    final InvoiceDraft draft = _input.draft(_invoice.patientId);
    final int paid = _invoice.receivedMinor;
    void change(VoidCallback update) => setState(update);
    final String? problem = _triedSave && draft.totalMinor < paid
        ? _t.belowPaid(Money.format(paid))
        : _error == null
        ? null
        : AppStrings.fromKey(_error!.userMessageKey);
    final sections = <Widget>[
      CorrectionNotice(number: _invoice.summary.displayNumber, dropped: _dropped),
      InvoiceDetailsSection(patient: widget.patient, input: _input, enabled: enabled, onChanged: change),
      InvoiceLinesSection(
        input: _input,
        enabled: enabled,
        showMissing: _triedSave,
        onChanged: change,
        onAdd: _addLine,
      ),
      InvoiceDiscountSection(input: _input, subtotalMinor: draft.subtotalMinor, enabled: enabled, onChanged: change),
      CorrectionReasonSection(controller: _reason, enabled: enabled),
    ];
    return PopScope(
      canPop: !_saving && _pristine,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t.correctTitle(_invoice.summary.displayNumber)),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.backTooltip,
            onPressed: _saving ? null : _cancel,
          ),
        ),
        body: FormPageBody(
          isSaving: _saving,
          saveLabel: _t.issueCorrection,
          errorMessage: problem,
          onSave: _saving ? null : _save,
          onCancel: _saving ? null : _cancel,
          child: Form(
            key: _form,
            child: CorrectionLayout(
              sections: sections,
              summary: InvoiceSummaryPanel(draft: draft, alreadyPaidMinor: paid),
            ),
          ),
        ),
      ),
    );
  }
}
