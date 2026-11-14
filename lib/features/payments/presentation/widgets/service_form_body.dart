import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/form_page_body.dart';
import '../../domain/invoice_repository.dart';
import '../../domain/service_catalog_item.dart';
import '../service_catalog_providers.dart';
import 'service_form_fields.dart';

const _t = AppStrings.invoices;

/// Add or edit one service, with persistent Save and Cancel actions.
class ServiceFormBody extends ConsumerStatefulWidget {
  const ServiceFormBody({super.key, this.service});
  final ServiceCatalogItem? service;

  @override
  ConsumerState<ServiceFormBody> createState() => _ServiceFormBodyState();
}

class _ServiceFormBodyState extends ConsumerState<ServiceFormBody> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final ServiceFormInput _input = _initialInput(widget.service);
  late final ServiceFormInput _initial = _initialInput(widget.service);
  bool _confirmingDiscard = false;

  /// The version this form opened with. A conflicting save stays rejected
  /// until the user reopens the service and sees the other change.
  late final int? _version = widget.service?.version;

  static ServiceFormInput _initialInput(ServiceCatalogItem? service) => ServiceFormInput(
    name: TextEditingController(text: service?.name ?? ''),
    price: TextEditingController(text: service == null ? '' : Money.editable(service.priceMinor)),
    sessions: TextEditingController(
      text: service != null && service.isPackage ? '${service.sessionsPerUnit}' : '6',
    ),
    type: service?.type ?? ServiceType.ptSession,
    package: service?.isPackage ?? false,
    credit: service?.creditsDoctors ?? true,
    active: service?.active ?? true,
  );

  @override
  void initState() {
    super.initState();
    for (final controller in [_input.name, _input.price, _input.sessions]) {
      controller.addListener(_refresh);
    }
    Future.microtask(() {
      if (mounted) ref.read(serviceCatalogControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    for (final input in [_input, _initial]) {
      input.name.dispose();
      input.price.dispose();
      input.sessions.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  ServiceDraft _draftOf(ServiceFormInput input) => ServiceDraft(
    id: widget.service?.id,
    version: _version,
    name: input.name.text,
    type: input.type,
    sessionsPerUnit: input.sessionCount ?? -1,
    priceMinor: input.priceMinor ?? -1,
    creditsDoctors: input.credit,
    active: input.active,
  );

  bool get _dirty =>
      !_draftOf(_input).sameAs(_draftOf(_initial)) ||
      (_input.price.text.trim() != _initial.price.text.trim());

  void _leave() => context.canPop() ? context.pop() : context.go(AppRoutes.serviceCatalog);

  Future<void> _cancel() async {
    if (ref.read(serviceCatalogControllerProvider).saving || _confirmingDiscard) return;
    if (!_dirty) return _leave();
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
    if (!(_form.currentState?.validate() ?? false)) return;
    final result = await ref.read(serviceCatalogControllerProvider.notifier).save(_draftOf(_input));
    if (!mounted || !result.isSuccess) return;
    AppSnackbar.show(
      context,
      message: widget.service == null ? _t.serviceAdded : _t.serviceSaved,
      variant: AppSnackbarVariant.success,
    );
    _leave();
  }

  Future<void> _remove() async {
    final service = widget.service!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: _t.removeTitle,
        message: _t.removeMessage(service.name),
        confirmLabel: _t.removeService,
        cancelLabel: AppStrings.keepEditing,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(serviceCatalogControllerProvider.notifier).remove(service);
    if (!mounted) return;
    result.when(
      success: (removal) {
        AppSnackbar.show(
          context,
          message: removal == ServiceRemoval.deleted ? _t.serviceDeleted : _t.serviceRemoved,
          variant: AppSnackbarVariant.success,
        );
        _leave();
      },
      failure: (_) {},
    );
  }

  /// Offers a removed service again, keeping any edits made on the form.
  Future<void> _restore() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    _input.active = true;
    final result = await ref.read(serviceCatalogControllerProvider.notifier).save(_draftOf(_input));
    if (!mounted) return;
    if (!result.isSuccess) {
      _input.active = false;
      return;
    }
    AppSnackbar.show(context, message: _t.serviceRestored, variant: AppSnackbarVariant.success);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceCatalogControllerProvider);
    final bool isNew = widget.service == null;
    final bool dirty = _dirty;
    return PopScope(
      canPop: !state.saving && !dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? _t.addService : _t.editService),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.backTooltip,
            onPressed: state.saving ? null : _cancel,
          ),
        ),
        body: FormPageBody(
          maxWidth: AppSizes.formLayoutMaxWidth,
          isSaving: state.saving,
          saveLabel: isNew ? _t.addService : AppStrings.saveChanges,
          errorMessage: state.error == null
              ? null
              : AppStrings.fromKey(state.error!.userMessageKey),
          onSave: state.saving || (!isNew && !dirty) ? null : _save,
          onCancel: state.saving ? null : _cancel,
          child: Form(
            key: _form,
            child: ServiceFormFields(
              input: _input,
              original: widget.service,
              enabled: !state.saving,
              onChanged: (change) => setState(change),
              onSubmit: _save,
              onRemove: _remove,
              onRestore: _restore,
            ),
          ),
        ),
      ),
    );
  }
}
