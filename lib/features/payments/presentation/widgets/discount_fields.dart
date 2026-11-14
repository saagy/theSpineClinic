import 'package:flutter/widgets.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_draft.dart';

/// A discount as two linked fields: typing a percentage fills in the amount
/// and typing an amount fills in the percentage. The field typed in last
/// holds the discount. Percentages are of [discountBaseMinor]. Invalid typed
/// values read as null so validators can report them.
mixin DiscountFields {
  /// What a percentage is taken of, such as the subtotal of a new invoice.
  int get discountBaseMinor;

  /// The field typed in last; none while both are empty.
  DiscountKind discountKind = DiscountKind.none;
  final TextEditingController discountPercent = TextEditingController();
  final TextEditingController discountAmount = TextEditingController();

  /// Basis points for a percentage (`12.5` → 1250), piasters for an amount.
  int? get discountValue => switch (discountKind) {
    DiscountKind.none => 0,
    DiscountKind.percent => Money.parseMinor(discountPercent.text),
    DiscountKind.amount => Money.parseMinor(discountAmount.text),
  };

  /// Records which field the user just typed in and mirrors it into the other.
  void editDiscount(DiscountKind typed) {
    final TextEditingController field = typed == DiscountKind.percent ? discountPercent : discountAmount;
    discountKind = field.text.trim().isEmpty ? DiscountKind.none : typed;
    syncDiscount();
  }

  /// Loads a saved discount, for example when correcting an invoice.
  void setDiscount(DiscountKind kind, int value) {
    discountKind = kind;
    discountPercent.clear();
    discountAmount.clear();
    if (kind == DiscountKind.none) return;
    (kind == DiscountKind.percent ? discountPercent : discountAmount).text = Money.editable(value);
    syncDiscount();
  }

  void clearDiscount() => setDiscount(DiscountKind.none, 0);

  /// Rewrites the mirrored field from the one that holds the discount, for
  /// example after the base changes. A percentage keeps its rate and a fixed
  /// amount keeps its value. The mirror stays empty while the typed value is
  /// invalid or there is nothing to discount.
  void syncDiscount() {
    final int base = discountBaseMinor;
    final int? value = discountValue;
    String mirror = '';
    if (value != null && base > 0) {
      if (discountKind == DiscountKind.percent && value <= 10000) {
        mirror = Money.editable(InvoiceDraft.percentOf(base, value));
      } else if (discountKind == DiscountKind.amount && value <= base) {
        mirror = Money.editable((value * 10000 + base ~/ 2) ~/ base);
      }
    }
    final TextEditingController other = discountKind == DiscountKind.amount ? discountPercent : discountAmount;
    if (discountKind == DiscountKind.none) discountPercent.clear();
    if (other.text != mirror) other.text = mirror;
  }
}
