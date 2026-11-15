import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/money.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_action.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_detail.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/invoice_detail_fixture.dart';
import '../../fixtures/invoice_detail_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';

const t = AppStrings.invoiceDetail;

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

FakeInvoiceRepository repoWith(InvoiceDetail detail, {Result<String>? result}) =>
    FakeInvoiceRepository(details: {detail.id: detail}, actionResult: result);

Finder get menus => find.byTooltip(AppStrings.moreActions);

void main() {
  testWidgets('front desk reads the invoice in a side panel and records a payment', (tester) async {
    final repo = repoWith(partPaidDetail);
    await pumpInvoiceDetail(tester, repo: repo, user: frontDesk);
    expect(find.text(t.title('TG-00042')), findsOneWidget);
    expect(find.byTooltip(AppStrings.close), findsOneWidget); // Docked beside the patient page.
    expect(find.text(t.receipt('TG-00031')), findsOneWidget);
    expect(find.text(t.voided), findsOneWidget); // The voided receipt stays on record.
    expect(find.text(Money.format(150000)), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, t.refund), findsNothing);

    await tap(tester, menus.first); // No invoice menu, so this is a receipt's.
    expect(find.text(t.print), findsOneWidget);
    expect(find.text(t.voidAction), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tap(tester, find.widgetWithText(FilledButton, t.recordPayment));
    await fill(tester, t.amount, '2000');
    await tap(tester, find.widgetWithText(FilledButton, t.recordPayment).last);
    expect(find.text(t.amountTooHigh(Money.format(150000))), findsOneWidget);
    expect(repo.actions, isEmpty);

    await fill(tester, t.amount, '500');
    await tap(tester, find.text(t.visa));
    await tap(tester, find.widgetWithText(FilledButton, t.recordPayment).last);
    final action = repo.actions.single;
    expect(action.kind, InvoiceActionKind.receiptCreate);
    expect(action.toPayload(), {
      'id': 'invoice-42',
      'version': 3,
      'amount_minor': 50000,
      'method': 'visa',
      'branch': 'tagamoa',
    });
    expect(find.text(t.paymentRecorded), findsOneWidget);
  });

  testWidgets('a phone shows the invoice full screen', (tester) async {
    await pumpInvoiceDetail(tester, repo: repoWith(partPaidDetail), user: frontDesk, width: 390);
    expect(find.byTooltip(AppStrings.backTooltip), findsOneWidget);
    expect(find.byTooltip(AppStrings.close), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment staff void a receipt only with a reason', (tester) async {
    final repo = repoWith(partPaidDetail);
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, menus.first); // Receipt TG-00031; the invoice menu comes last.
    await tap(tester, find.text(t.voidAction));
    expect(find.text(t.voidReceiptHelp(Money.format(100000))), findsOneWidget);
    // The fixture payment was taken on an earlier day: the dialog says that
    // cancelling it changes that day and points to a refund instead.
    expect(find.textContaining("changes that day's totals"), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, t.voidReceiptTitle);
    await tap(tester, confirm);
    expect(find.text(t.reasonRequired), findsOneWidget);
    expect(repo.actions, isEmpty);
    await fill(tester, t.reason, 'Wrong patient');
    await tap(tester, confirm);
    expect(repo.actions.single.kind, InvoiceActionKind.receiptVoid);
    expect(repo.actions.single.toPayload()['reason'], 'Wrong patient');
    expect(find.text(t.receiptVoided), findsOneWidget);
  });

  testWidgets('a later refund locks earlier documents and says how to unlock them', (tester) async {
    await pumpInvoiceDetail(tester, repo: repoWith(refundedDetail), user: cashier);
    await tap(tester, menus.last);
    // Edit and Cancel are both locked by the refund and say the same step.
    expect(find.textContaining(t.voidNeedsNoRefunds), findsNWidgets(2));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tap(tester, menus.first); // The receipt recorded before the refund.
    expect(find.textContaining(t.lockedByRefund), findsNWidgets(2));
  });

  testWidgets('a paid invoice entered by mistake is cancelled with its payments', (tester) async {
    final repo = repoWith(partPaidDetail);
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, menus.last);
    await tap(tester, find.text(t.voidInvoice));
    expect(find.text(t.paidCancelMistake), findsOneWidget);
    expect(find.text(t.paidCancelGivenBack), findsOneWidget);
    await tap(tester, find.text(t.paidCancelMistake));
    final confirm = find.widgetWithText(FilledButton, t.cancelWithPayments);
    await fill(tester, t.reason, 'Wrong patient');
    await tap(tester, confirm);
    expect(repo.actions.single.kind, InvoiceActionKind.invoiceVoidAll);
    expect(repo.actions.single.toPayload()['reason'], 'Wrong patient');
    expect(find.text(t.invoiceVoidedDone), findsOneWidget);
  });

  testWidgets('money given back on a paid invoice leads to the refund form', (tester) async {
    final repo = repoWith(partPaidDetail);
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, menus.last);
    await tap(tester, find.text(t.voidInvoice));
    await tap(tester, find.text(t.paidCancelGivenBack));
    expect(repo.actions, isEmpty);
    expect(find.text(t.refundTitle), findsWidgets);
  });

  testWidgets('a rejected command stays open and explains why', (tester) async {
    final repo = repoWith(
      sampleDetail(),
      result: const Result.failure(
        DatabaseException(
          code: 'invoice/sessions_in_use',
          message: 'sessions_in_use',
          userMessageKey: 'invoice_sessions_in_use',
        ),
      ),
    );
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, menus.first);
    await tap(tester, find.text(t.voidInvoice));
    await fill(tester, t.reason, 'Duplicate');
    await tap(tester, find.widgetWithText(FilledButton, t.voidInvoice));
    expect(find.text(AppStrings.fromKey('invoice_sessions_in_use')), findsOneWidget);
    expect(find.text(t.voidInvoiceHelp), findsOneWidget);
  });

  testWidgets('a refund cancels unused sessions and pays back the excess', (tester) async {
    final repo = repoWith(sampleDetail(receipts: [receiptJson(31, 300000)]));
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, find.widgetWithText(OutlinedButton, t.refund));
    expect(find.text(t.paybackNone), findsOneWidget);
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip(t.increaseSessions), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    // The patient has four unused PT sessions, so four is the most.
    expect(find.text(AppStrings.invoices.ptSessions(4)), findsOneWidget);
    await fill(tester, t.refundValue, '1600');
    expect(find.text(Money.format(160000)), findsWidgets);
    expect(find.text(Money.format(140000)), findsOneWidget); // New invoice value.

    final save = find.widgetWithText(FilledButton, t.recordRefund);
    await tap(tester, save);
    expect(find.text(t.paybackMethodRequired), findsOneWidget);
    expect(find.text(t.reasonRequired), findsOneWidget);
    expect(repo.actions, isEmpty);

    await tap(tester, find.text(t.cash));
    await fill(tester, t.reason, 'Patient is travelling');
    await tap(tester, save);
    expect(repo.actions.single.toPayload(), {
      'id': 'invoice-42',
      'version': 3,
      'lines': [
        {'line_id': 'line-1', 'sessions': 4, 'value_minor': 160000},
      ],
      'payback_minor': 160000,
      'payback_method': 'cash',
      'branch': 'tagamoa',
      'reason': 'Patient is travelling',
    });
    expect(find.text(t.refundRecorded), findsOneWidget);
    expect(find.text(t.title('TG-00042')), findsOneWidget);
  });

  testWidgets('a correction starts from the original and must cover money received', (
    tester,
  ) async {
    final replacement = InvoiceDetail.fromJson(
      invoiceDetailJson(
        id: 'invoice-43',
        number: 43,
        replaces: {'id': 'invoice-42', 'number': 42, 'branch': 'tagamoa'},
      ),
    );
    final repo = repoWith(partPaidDetail, result: const Result.success('invoice-43'));
    repo.details = {...repo.details, replacement.id: replacement};
    await pumpInvoiceDetail(tester, repo: repo, user: cashier);
    await tap(tester, menus.last);
    await tap(tester, find.text(t.correctInvoice));
    expect(find.text(t.correctTitle('TG-00042')), findsOneWidget);
    expect(find.text('Dr. Mariam Khaled'), findsOneWidget); // Line doctors carried over.
    expect(find.text(t.alreadyPaid), findsOneWidget);

    await tap(tester, find.byTooltip(AppStrings.invoices.removeLine).first);
    await fill(tester, t.reason, 'Wrong package');
    final save = find.widgetWithText(FilledButton, t.issueCorrection);
    await tap(tester, save);
    expect(find.text(t.belowPaid(Money.format(150000))), findsOneWidget);
    expect(repo.actions, isEmpty);

    await tap(tester, find.widgetWithText(OutlinedButton, AppStrings.invoices.addLine));
    await tap(tester, find.text('6 PT sessions').last);
    await tap(tester, save);
    final payload = repo.actions.single.toPayload();
    expect(repo.actions.single.kind, InvoiceActionKind.invoiceCorrect);
    expect(payload['reason'], 'Wrong package');
    final invoice = payload['invoice']! as Map<String, Object?>;
    expect(invoice.containsKey('payments'), isFalse);
    expect((invoice['lines']! as List).map((line) => (line as Map)['service_id']), ['ia', 'pt6']);
    expect(find.text(t.title('TG-00043')), findsOneWidget); // Lands on the corrected invoice.
    expect(find.text(t.corrects('TG-00042')), findsOneWidget);
  });

  testWidgets('a correction names services that are no longer sold', (tester) async {
    final detail = sampleDetail(ptService: 'pt12'); // Archived in the catalog fixture.
    await pumpInvoiceDetail(tester, repo: repoWith(detail), user: cashier);
    await tap(tester, menus.last);
    await tap(tester, find.text(t.correctInvoice));
    expect(find.text(t.droppedServices('6 PT sessions')), findsOneWidget);
  });

  testWidgets('a missing invoice says so instead of spinning', (tester) async {
    await pumpInvoiceDetail(tester, repo: FakeInvoiceRepository(), user: frontDesk);
    expect(find.text(t.notFound), findsOneWidget);
  });
}
