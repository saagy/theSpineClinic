part of 'billing_editor_screen.dart';

extension _BillingEditorForm on _BillingEditorScreenState {
  Widget _fields(bool busy) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BillingPartyField(
          label: billingText.patient,
          party: _patient,
          action: billingText.pickPatient,
          onTap: busy ? null : () => _pick(BillingLookup.patient),
        ),
        BillingPartyField(
          label: billingText.doctor,
          party: _doctor,
          action: billingText.pickDoctor,
          onTap: busy ? null : () => _pick(BillingLookup.doctor),
        ),
        BillingPartyField(
          label: billingText.consultant,
          party: _consultant,
          action: billingText.pickConsultant,
          onTap: busy
              ? null
              : () => _pick(BillingLookup.senior),
          onClear: busy || _consultant == null
              ? null
              : () => _update(() => _consultant = null),
        ),
        const SizedBox(height: AppSizes.p12),
        BillingBranchField(
          branch: _branch,
          onChanged: busy ? null : (branch) => _update(() => _branch = branch),
        ),
        const SizedBox(height: AppSizes.p12),
        OutlinedButton.icon(
          onPressed: busy ? null : _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text('${billingText.serviceDate} · ${billingDate(_date)}'),
        ),
        const SizedBox(height: AppSizes.p24),
        BillingEditorLines(
          lines: _lines,
          busy: busy,
          onAdd: _add,
          onRefresh: _refreshPrices,
          onRemove: (index) => _update(() => _lines.removeAt(index)),
          onQuantity: (index, qty) => _update(
            () => _lines[index] = BillingDraftLine(_lines[index].item, qty),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        TextFormField(
          controller: _discount,
          enabled: !busy,
          style: AppTextStyles.body,
          decoration: InputDecoration(labelText: billingText.discount),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _update(() {}),
          validator: (text) {
            final value = parseBillingMinor(text ?? '');
            return value == null || value > 10000
                ? billingText.discountError
                : null;
          },
        ),
      ],
    ),
  );

  Future<void> _pick(BillingLookup kind) async {
    final party = await pickBillingParty(context, kind);
    if (!mounted || party == null) return;
    _update(() {
      if (kind == BillingLookup.patient) {
        _patient = party;
        _branch ??= party.branch;
      } else if (kind == BillingLookup.senior) {
        _consultant = party;
      } else {
        _doctor = party;
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (mounted && date != null) _update(() => _date = date);
  }

  Future<void> _add() async {
    final item = await pickBillingService(
      context,
      _lines.map((line) => line.item.id).toSet(),
    );
    if (mounted && item != null) {
      _update(() => _lines.add(BillingDraftLine(item, 1)));
    }
  }

  Future<void> _refreshPrices() async {
    _update(() => _refreshingPrices = true);
    final updated = await loadBillingPrices(ref, _lines);
    if (!mounted) return;
    _update(() {
      _refreshingPrices = false;
      if (updated != null) _lines.setAll(0, updated);
    });
    billingMessage(
      context,
      updated == null ? billingText.catalogChanged : billingText.pricesUpdated,
    );
  }

  Future<void> _recover() async {
    final commit = await recoverBilling(
      context,
      ref,
      BillingAction.draft,
      widget.invoice?.id ?? 'new',
    );
    if (mounted && commit?.invoiceId != null) {
      Navigator.pop(context, commit!.invoiceId);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_patient == null ||
        _doctor == null ||
        _branch == null ||
        _lines.isEmpty) {
      billingMessage(context, billingText.requiredDetails);
      return;
    }
    final commit = await submitBilling(
      context,
      ref,
      BillingCommand.draft(
        invoice: widget.invoice,
        patient: _patient!,
        doctor: _doctor!,
        consultant: _consultant,
        branch: _branch!,
        date: _date,
        discount: parseBillingMinor(_discount.text)!,
        lines: _lines,
      ),
    );
    if (mounted && commit?.invoiceId != null) {
      Navigator.pop(context, commit!.invoiceId);
    }
  }
}
