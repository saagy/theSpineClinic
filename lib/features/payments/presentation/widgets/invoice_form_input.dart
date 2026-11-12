import 'package:flutter/widgets.dart';
import '../../../../core/utils/money.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_draft.dart';
import '../../domain/service_catalog_item.dart';
import 'invoice_line_editor.dart';

/// Everything the new-invoice form holds. Invalid typed amounts read as null
/// so validators can report them; the preview treats them as zero.
class InvoiceFormInput {
  InvoiceFormInput({required this.branch, required this.date});

  ClinicLocation branch;
  DateTime date;
  final List<InvoiceLineInput> lines = [];
  /// The discount field typed in last, which holds the discount; the other
  /// field mirrors it in its own unit. None while both are empty.
  DiscountKind discountKind = DiscountKind.none;
  final TextEditingController discountPercent = TextEditingController();
  final TextEditingController discountAmount = TextEditingController();
  final TextEditingController cash = TextEditingController();
  final TextEditingController visa = TextEditingController();
  final TextEditingController note = TextEditingController();
  int _nextKey = 0;

  int nextKey() => _nextKey++;

  /// Applies a reloaded catalog (for example after a rejected price): each
  /// line takes the current price and archived services are dropped.
  void syncCatalog(List<ServiceCatalogItem> services) {
    final byId = {for (final service in services) service.id: service};
    lines.removeWhere((line) => !byId.containsKey(line.service.id));
    for (final line in lines) {
      line.service = byId[line.service.id]!;
    }
  }

  int get subtotalMinor => lines.fold(0, (sum, line) => sum + line.toDraft().grossMinor);

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
  /// example after the subtotal changes. A percentage keeps its rate and a
  /// fixed amount keeps its value. The mirror stays empty while the typed
  /// value is invalid or there is nothing to discount.
  void syncDiscount() {
    final int subtotal = subtotalMinor;
    final int? value = discountValue;
    String mirror = '';
    if (value != null && subtotal > 0) {
      if (discountKind == DiscountKind.percent && value <= 10000) {
        mirror = Money.editable(InvoiceDraft.percentOf(subtotal, value));
      } else if (discountKind == DiscountKind.amount && value <= subtotal) {
        mirror = Money.editable((value * 10000 + subtotal ~/ 2) ~/ subtotal);
      }
    }
    final TextEditingController other = discountKind == DiscountKind.amount ? discountPercent : discountAmount;
    if (discountKind == DiscountKind.none) discountPercent.clear();
    if (other.text != mirror) other.text = mirror;
  }

  int? get cashMinor => _optional(cash.text);
  int? get visaMinor => _optional(visa.text);

  static int? _optional(String text) => text.trim().isEmpty ? 0 : Money.parseMinor(text);

  bool get isPristine =>
      lines.isEmpty &&
      discountKind == DiscountKind.none &&
      [cash, visa, note].every((controller) => controller.text.trim().isEmpty);

  InvoiceDraft draft(String patientId) => InvoiceDraft(
    patientId: patientId,
    branch: branch,
    invoiceDate: date,
    lines: [for (final line in lines) line.toDraft()],
    discountKind: discountKind,
    discountValue: discountValue ?? 0,
    cashMinor: cashMinor ?? 0,
    visaMinor: visaMinor ?? 0,
    note: note.text,
  );

  void addListener(VoidCallback listener) {
    for (final controller in [discountPercent, discountAmount, cash, visa, note]) {
      controller.addListener(listener);
    }
  }

  void dispose() {
    for (final controller in [discountPercent, discountAmount, cash, visa, note]) {
      controller.dispose();
    }
  }
}
