import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/money.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_action.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_detail.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_draft.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_summary.dart';
import 'package:spine_clinic_app/features/payments/presentation/invoice_document_pdf.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/invoice_detail_fixture.dart';
import '../../fixtures/invoice_detail_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';

const t = AppStrings.invoiceDetail;
const d = AppStrings.invoiceDiscount;

Future<void> fill(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.widgetWithText(LabeledFormField, label),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field.first);
  await tester.enterText(field.first, text);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

DiscountDraft draftFor(InvoiceDetail invoice, DiscountKind kind, int value) =>
    DiscountDraft(invoice: invoice, kind: kind, value: value, branch: ClinicLocation.tagamoa);

void main() {
  group('discount arithmetic matches the database', () {
    test('a percentage is of the value now and nothing goes back while underpaid', () {
      final invoice = sampleDetail(
        receipts: [receiptJson(31, 100000)],
        refunds: [refundJson(4, value: 60000, payback: 0, sessions: 1)],
      );
      final draft = draftFor(invoice, DiscountKind.percent, 1000); // 10% of 2,400.
      expect(draft.discountMinor, 24000);
      expect(draft.newValueMinor, 216000);
      expect(draft.paybackMinor, 0);
      expect(draft.dueAfterMinor, 116000);
    });

    test('money comes back only above the new value', () {
      final invoice = sampleDetail(receipts: [receiptJson(31, 300000)]);
      final draft = draftFor(invoice, DiscountKind.amount, 45000);
      expect(draft.paybackMinor, 45000);
      expect(draft.dueAfterMinor, 0);
      expect(draft.toBody()['discount'], {'kind': 'amount', 'value': 45000});
    });
  });

  testWidgets('only payment staff see Add discount', (tester) async {
    final repo = FakeInvoiceRepository(details: {'invoice-42': partPaidDetail});
    await pumpInvoiceDetail(tester, repo: repo, user: frontDesk);
    expect(find.widgetWithText(OutlinedButton, d.addDiscount), findsNothing);
  });

  testWidgets('a discount keeps the invoice and pays back what was overpaid', (tester) async {
    final repo = FakeInvoiceRepository(
      details: {'invoice-42': sampleDetail(receipts: [receiptJson(31, 300000)])},
    );
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, find.widgetWithText(OutlinedButton, d.addDiscount));
    expect(find.text(d.screenTitle('TG-00042')), findsOneWidget);

    final save = find.widgetWithText(FilledButton, d.record);
    await tap(tester, save);
    expect(find.text(d.empty), findsOneWidget);
    expect(repo.actions, isEmpty);

    // 10% of 3,000: the other field fills in, and 300 goes back.
    await fill(tester, AppStrings.invoices.discountPercentLabel, '10');
    expect(find.widgetWithText(TextField, '300'), findsOneWidget);
    expect(find.text(Money.format(270000)), findsOneWidget); // New invoice value.
    await tap(tester, save);
    // Paid in cash, so money handed back starts as cash.
    expect(find.text(t.paybackMethodRequired), findsNothing);
    expect(find.text(t.reasonRequired), findsOneWidget);
    expect(repo.actions, isEmpty);

    await fill(tester, t.reason, 'Approved by the head receptionist');
    await tap(tester, save);
    expect(repo.actions.single.kind, InvoiceActionKind.discountCreate);
    expect(repo.actions.single.toPayload(), {
      'id': 'invoice-42',
      'version': 3,
      'discount': {'kind': 'percent', 'value': 1000},
      'payback_minor': 30000,
      'payback_method': 'cash',
      'branch': 'tagamoa',
      'reason': 'Approved by the head receptionist',
    });
    expect(find.text(d.recorded), findsOneWidget);
    expect(find.text(t.title('TG-00042')), findsOneWidget);
  });

  testWidgets('a recorded discount reads as a discount and cancels as one', (tester) async {
    final invoice = sampleDetail(
      receipts: [receiptJson(31, 300000)],
      refunds: [discountJson(2, value: 30000, payback: 30000)],
    );
    final repo = FakeInvoiceRepository(details: {'invoice-42': invoice});
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    expect(invoice.summary.status, isNot(equals(InvoiceStatus.refunded)));
    expect(find.text(d.number('TG-00002')), findsOneWidget);
    expect(find.text(t.refundNumber('TG-00002')), findsNothing);
    expect(find.text(d.laterDiscounts), findsOneWidget);
    expect(find.text(t.refunded), findsNothing);

    // Receipt, then discount; the invoice menu comes last.
    await tap(tester, find.byTooltip(AppStrings.moreActions).at(1));
    await tap(tester, find.text(t.voidAction));
    expect(find.text(d.voidHelp), findsOneWidget);
    await fill(tester, t.reason, 'Entered by mistake');
    await tap(tester, find.widgetWithText(FilledButton, d.voidTitle));
    expect(repo.actions.single.kind, InvoiceActionKind.refundVoid);
    expect(repo.actions.single.toPayload()['refund_id'], 'discount-2');
    expect(find.text(d.voided), findsOneWidget);
  });

  test('a discount prints as a discount without a sessions column', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final invoice = sampleDetail(refunds: [discountJson(2, value: 30000)]);
    final bytes = await InvoiceDocumentPdf.render(invoice, refund: invoice.refunds.single);
    expect(bytes, isNotEmpty);
    expect(invoice.refunds.single.isDiscount, isTrue);
  });
}
