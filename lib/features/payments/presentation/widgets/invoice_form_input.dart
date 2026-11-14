import 'package:flutter/widgets.dart';
import '../../../../core/utils/money.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_draft.dart';
import '../../domain/service_catalog_item.dart';
import 'discount_fields.dart';
import 'invoice_line_editor.dart';

/// Everything the new-invoice form holds. Invalid typed amounts read as null
/// so validators can report them; the preview treats them as zero.
class InvoiceFormInput with DiscountFields {
  InvoiceFormInput({required this.branch, required this.date});

  ClinicLocation branch;
  DateTime date;
  final List<InvoiceLineInput> lines = [];
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

  /// A new invoice's discount is a share of its subtotal.
  @override
  int get discountBaseMinor => subtotalMinor;

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
