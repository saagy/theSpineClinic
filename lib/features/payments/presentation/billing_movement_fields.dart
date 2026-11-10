part of 'billing_movement_dialog.dart';

extension _BillingMovementFields on _BillingMovementDialogState {
  List<Widget> _paymentFields() => [
    BillingFact(
      _refund ? billingText.refundable : billingText.outstanding,
      billingAmount(_limit),
    ),
    const SizedBox(height: AppSizes.p8),
    TextFormField(
      controller: _amount,
      autofocus: true,
      style: AppTextStyles.body,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: billingText.amount),
      validator: (value) {
        final amount = parseBillingMinor(value ?? '');
        if (amount == null || amount <= 0) return billingText.positiveAmount;
        return amount > _limit
            ? (_refund ? billingText.refundLimit : billingText.receiptLimit)
            : null;
      },
    ),
    const SizedBox(height: AppSizes.p12),
    RecordMenuSelect<BillingMethod>(
      label: billingText.method,
      value: _method,
      isField: true,
      options: [
        for (final method in BillingMethod.values)
          RecordMenuAction(
            method,
            billingMethodLabel(method),
            method == BillingMethod.cash
                ? Icons.payments_outlined
                : Icons.credit_card,
          ),
      ],
      onChanged: (value) => _update(() => _method = value),
    ),
    const SizedBox(height: AppSizes.p12),
  ];

  List<Widget> _returnFields() {
    final invoice = widget.invoice;
    final total = invoice.lines.fold(0, (sum, line) {
      final prior = line.quantity - invoice.remainingQuantity(line);
      final added = _quantities[line.id] ?? 0;
      return sum +
          (line.net * (prior + added) ~/ line.quantity) -
          (line.net * prior ~/ line.quantity);
    });
    return [
      for (final line in invoice.lines.where(
        (line) => invoice.remainingQuantity(line) > 0,
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p8),
          child: TextFormField(
            key: ValueKey(line.id),
            initialValue: '0',
            style: AppTextStyles.body,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: line.name,
              helperText:
                  '${billingText.quantity} 0–${invoice.remainingQuantity(line)}',
            ),
            validator: (text) {
              final quantity = int.tryParse(text ?? '');
              return quantity == null ||
                      quantity < 0 ||
                      quantity > invoice.remainingQuantity(line)
                  ? billingText.returnQuantityError
                  : null;
            },
            onChanged: (text) {
              final quantity = int.tryParse(text);
              _update(
                () => _quantities[line.id] =
                    quantity != null &&
                        quantity >= 0 &&
                        quantity <= invoice.remainingQuantity(line)
                    ? quantity
                    : 0,
              );
            },
          ),
        ),
      BillingFact(
        billingText.creditPreview,
        billingAmount(total),
        emphasis: true,
      ),
      BillingFact(
        billingText.debtReduced,
        billingAmount(min(total, invoice.outstanding)),
      ),
      BillingFact(
        billingText.potentialRefund,
        billingAmount(max(0, total - invoice.outstanding)),
      ),
      const SizedBox(height: AppSizes.p12),
    ];
  }
}
