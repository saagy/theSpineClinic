import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/form_page_body.dart';
import '../../../auth/domain/staff.dart';
import '../../../patient/domain/patient.dart';
import '../../domain/service_catalog_item.dart';
import '../invoice_providers.dart';
import 'invoice_details_section.dart';
import 'invoice_discount_section.dart';
import 'invoice_form_input.dart';
import 'invoice_line_editor.dart';
import 'invoice_lines_section.dart';
import 'invoice_money_sections.dart';
import 'invoice_summary_panel.dart';
import 'service_picker_sheet.dart';

const _t = AppStrings.invoices;

/// Builds and issues one invoice, with optional payment received now.
class NewInvoiceForm extends ConsumerStatefulWidget {
  const NewInvoiceForm({
    super.key,
    required this.patient,
    required this.services,
    required this.assignedDoctors,
    required this.canDiscount,
  });
  final Patient patient;

  /// Active services only.
  final List<ServiceCatalogItem> services;
  final List<Staff> assignedDoctors;
  final bool canDiscount;

  @override
  ConsumerState<NewInvoiceForm> createState() => _NewInvoiceFormState();
}

class _NewInvoiceFormState extends ConsumerState<NewInvoiceForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final InvoiceFormInput _input = InvoiceFormInput(
    branch: widget.patient.clinic,
    date: DateUtils.dateOnly(DateTime.now()),
  );
  bool _triedSave = false;
  bool _confirmingDiscard = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_refresh);
    Future.microtask(() {
      if (mounted) ref.read(invoiceCreateControllerProvider.notifier).clearError();
    });
  }

  /// A reloaded catalog (for example after a rejected price) updates each
  /// line to the current price and drops services that were archived.
  @override
  void didUpdateWidget(NewInvoiceForm old) {
    super.didUpdateWidget(old);
    if (identical(old.services, widget.services)) return;
    _input.syncCatalog(widget.services);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _leave() => context.canPop() ? context.pop() : context.go(AppRoutes.patientDetail.replaceFirst(':id', widget.patient.id));

  Future<void> _addLine() async {
    final ServiceCatalogItem? service = await ServicePickerSheet.show(context, widget.services);
    if (service == null || !mounted) return;
    // New lines start with the last chosen doctors, else the patient's own.
    final List<Staff> previous = _input.lines.reversed
        .firstWhere((line) => line.doctors.isNotEmpty, orElse: () => InvoiceLineInput(key: -1, service: service))
        .doctors;
    final List<Staff> doctors = !service.creditsDoctors
        ? const []
        : previous.isNotEmpty
        ? previous
        : widget.assignedDoctors.where((doctor) => doctor.isActive).toList();
    setState(() => _input.lines.add(InvoiceLineInput(key: _input.nextKey(), service: service, doctors: doctors)));
  }

  Future<void> _cancel() async {
    if (ref.read(invoiceCreateControllerProvider).saving || _confirmingDiscard) return;
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
    final bool valid = _form.currentState?.validate() ?? false;
    if (!valid || _input.lines.isEmpty) return;
    final result = await ref.read(invoiceCreateControllerProvider.notifier).create(_input.draft(widget.patient.id));
    if (!mounted || !result.isSuccess) return;
    AppSnackbar.show(context, message: _t.invoiceCreated, variant: AppSnackbarVariant.success);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceCreateControllerProvider);
    final bool enabled = !state.saving;
    final draft = _input.draft(widget.patient.id);
    void change(VoidCallback update) => setState(update);
    final sections = [
      InvoiceDetailsSection(patient: widget.patient, input: _input, enabled: enabled, onChanged: change),
      InvoiceLinesSection(
        input: _input,
        enabled: enabled,
        showMissing: _triedSave,
        onChanged: change,
        onAdd: _addLine,
      ),
      if (widget.canDiscount)
        InvoiceDiscountSection(input: _input, subtotalMinor: draft.subtotalMinor, enabled: enabled, onChanged: change),
      InvoicePaymentSection(input: _input, totalMinor: draft.totalMinor, enabled: enabled, onChanged: change),
    ];
    final summary = InvoiceSummaryPanel(draft: draft);
    return PopScope(
      canPop: !state.saving && _input.isPristine,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t.newInvoice),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.backTooltip,
            onPressed: state.saving ? null : _cancel,
          ),
        ),
        body: FormPageBody(
          isSaving: state.saving,
          saveLabel: _t.createInvoice,
          errorMessage: state.error == null ? null : AppStrings.fromKey(state.error!.userMessageKey),
          onSave: state.saving ? null : _save,
          onCancel: state.saving ? null : _cancel,
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
