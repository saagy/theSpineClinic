part of 'billing_catalog_screen.dart';

class _CatalogEditDialog extends ConsumerStatefulWidget {
  const _CatalogEditDialog({this.item});
  final BillingItem? item;

  @override
  ConsumerState<_CatalogEditDialog> createState() => _CatalogEditDialogState();
}

class _CatalogEditDialogState extends ConsumerState<_CatalogEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _price = TextEditingController(
    text: widget.item == null ? null : billingDecimal(widget.item!.price),
  );
  late bool _active = widget.item?.active ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(billingWriterProvider).busy;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(
          widget.item == null
              ? billingText.newService
              : billingText.editService,
          style: AppTextStyles.headingSmall,
        ),
        scrollable: true,
        content: SizedBox(
          width: AppSizes.formLayoutMaxWidth,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  enabled: !busy,
                  maxLength: 160,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    labelText: billingText.serviceName,
                  ),
                  validator: (text) => (text ?? '').trim().isEmpty
                      ? billingText.nameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.p12),
                TextFormField(
                  controller: _price,
                  enabled: !busy,
                  style: AppTextStyles.body,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: billingText.unitPrice),
                  validator: (text) {
                    final value = parseBillingMinor(text ?? '');
                    return value == null || value <= 0 || value > 10000000000
                        ? billingText.positiveAmount
                        : null;
                  },
                ),
                const SizedBox(height: AppSizes.p12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(billingText.active, style: AppTextStyles.body),
                  value: _active,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _active = value),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (_error != null)
            TextButton(
              onPressed: busy ? null : _recover,
              child: Text(billingText.checkSave),
            ),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? billingText.saving : AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _show(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final commit = await submitBilling(
      context,
      ref,
      BillingCommand.item(
        widget.item,
        _name.text.trim(),
        parseBillingMinor(_price.text)!,
        _active,
      ),
      onMessage: _show,
    );
    if (mounted && commit != null) Navigator.pop(context);
  }

  Future<void> _recover() async {
    final commit = await recoverBilling(
      context,
      ref,
      BillingAction.item,
      widget.item?.id ?? 'new',
      onMessage: _show,
    );
    if (mounted && commit != null) Navigator.pop(context);
  }
}
