import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_draft.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/invoice_form_input.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/invoice_line_editor.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/new_invoice_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';
import 'new_invoice_test.dart' show addService, createButton, fill, t;

/// A form with one 6 PT sessions line (2,400 EGP) at [quantity].
InvoiceFormInput formWith({int quantity = 1}) {
  final input = InvoiceFormInput(branch: ClinicLocation.tagamoa, date: DateTime(2026, 11, 12));
  input.lines.add(InvoiceLineInput(key: 0, service: catalogFixture[1], quantity: quantity));
  return input;
}

void type(InvoiceFormInput input, DiscountKind kind, String text) {
  (kind == DiscountKind.percent ? input.discountPercent : input.discountAmount).text = text;
  input.editDiscount(kind);
}

String fieldText(WidgetTester tester, String label) => tester
    .widget<TextField>(find.descendant(of: find.widgetWithText(LabeledFormField, label), matching: find.byType(TextField)))
    .controller!
    .text;

void main() {
  test('a typed percentage fills in the amount', () {
    final input = formWith();
    type(input, DiscountKind.percent, '10');
    expect(input.discountAmount.text, '240');
    expect(input.draft('p').discountMinor, 24000);
    expect(input.draft('p').toPayload()['discount'], {'kind': 'percent', 'value': 1000});
  });

  test('a typed amount fills in the percentage and is recorded exactly', () {
    final input = formWith();
    type(input, DiscountKind.amount, '1000');
    expect(input.discountPercent.text, '41.67');
    expect(input.draft('p').toPayload()['discount'], {'kind': 'amount', 'value': 100000});
  });

  test('the field typed in last decides what a subtotal change keeps', () {
    final percent = formWith();
    type(percent, DiscountKind.percent, '10');
    percent.lines.single.quantity = 2;
    percent.syncDiscount();
    expect(percent.discountAmount.text, '480');

    final amount = formWith();
    type(amount, DiscountKind.amount, '600');
    expect(amount.discountPercent.text, '25');
    amount.lines.single.quantity = 2;
    amount.syncDiscount();
    expect(amount.discountPercent.text, '12.50');
    expect(amount.draft('p').discountMinor, 60000);
  });

  test('clearing the typed field or an invalid value empties the mirror', () {
    final input = formWith();
    type(input, DiscountKind.percent, '150');
    expect(input.discountAmount.text, isEmpty);
    type(input, DiscountKind.percent, '');
    expect(input.discountKind, DiscountKind.none);
    expect(input.isPristine, isFalse); // The line is still there.
    type(input, DiscountKind.amount, '200');
    input.clearDiscount();
    expect([input.discountPercent.text, input.discountAmount.text], ['', '']);
    expect(input.draft('p').discountMinor, 0);
  });

  test('a saved discount loads into its own field', () {
    final input = formWith();
    input.setDiscount(DiscountKind.percent, 1250);
    expect([input.discountPercent.text, input.discountAmount.text], ['12.50', '300']);
  });

  testWidgets('payment staff type either discount field and the other follows', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpNewInvoice(tester, repo: repo, user: cashier);
    await addService(tester, '6 PT sessions');
    await tester.ensureVisible(find.text(t.discountPercentLabel));
    await fill(tester, t.discountPercentLabel, '10');
    expect(fieldText(tester, t.discountAmountLabel), '240');

    await tester.tap(find.byTooltip(t.increase).first);
    await tester.pumpAndSettle();
    expect(fieldText(tester, t.discountAmountLabel), '480');

    await fill(tester, t.discountAmountLabel, '1200');
    expect(fieldText(tester, t.discountPercentLabel), '25');
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    final InvoiceDraft created = repo.created.single;
    expect([created.discountKind, created.discountValue, created.totalMinor], [DiscountKind.amount, 120000, 360000]);
  });

  testWidgets('remove discount clears both fields', (tester) async {
    await pumpNewInvoice(tester, repo: FakeInvoiceRepository(), user: cashier);
    await addService(tester, '6 PT sessions');
    await tester.ensureVisible(find.text(t.discountPercentLabel));
    await fill(tester, t.discountPercentLabel, '10');
    await tester.ensureVisible(find.text(t.removeDiscount));
    await tester.tap(find.text(t.removeDiscount));
    await tester.pumpAndSettle();
    expect([fieldText(tester, t.discountPercentLabel), fieldText(tester, t.discountAmountLabel)], ['', '']);
    expect(find.text(t.removeDiscount), findsNothing);
  });
}
