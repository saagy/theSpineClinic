import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/auth_redirect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_action.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_detail.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_summary.dart';
import 'package:spine_clinic_app/features/payments/presentation/invoice_document_pdf.dart';
import '../../fixtures/invoice_detail_fixture.dart';
import '../../fixtures/service_catalog_fixture.dart';

RefundDraft refund(InvoiceDetail invoice, int sessions, int value, {PaymentMethod? method}) => RefundDraft(
  invoice: invoice,
  branch: ClinicLocation.tagamoa,
  method: method,
  reason: ' Patient is travelling ',
  lines: [
    RefundLineDraft(line: invoice.lines[0], sessions: sessions, valueMinor: value),
    RefundLineDraft(line: invoice.lines[1]),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the invoice document parses with its figures and documents', () {
    final invoice = partPaidDetail;
    expect(invoice.summary.displayNumber, 'TG-00042');
    expect(invoice.summary.status, InvoiceStatus.partiallyPaid);
    expect(invoice.fileNumber, 107);
    expect(invoice.receipts, hasLength(3));
    expect(invoice.activeReceipts, hasLength(2));
    expect(invoice.receipts[1].voided?.reason, 'Entered on the wrong invoice');
    expect(invoice.receipts[2].method, PaymentMethod.visa);
    expect(invoice.dueMinor, 150000);
    expect(invoice.lines.first.doctors.single.name, 'Dr. Mariam Khaled');
  });

  test('state rules decide which actions are possible', () {
    final unpaid = sampleDetail();
    expect((unpaid.canRecordPayment, unpaid.canVoid, unpaid.canCorrect, unpaid.canRefund),
        (true, true, true, true));
    // Payments block voiding the invoice; refunds also block correcting it.
    expect((partPaidDetail.canVoid, partPaidDetail.canCorrect), (false, true));
    final refunded = refundedDetail;
    expect((refunded.canVoid, refunded.canCorrect, refunded.canRecordPayment), (false, false, false));
    // The receipt predates the refund, so the refund has to be voided first.
    expect(refunded.lockedByLaterRefund(refunded.receipts.single.recordedAt), isTrue);
    expect(refunded.lockedByLaterRefund(refunded.refunds.single.recordedAt), isFalse);
    expect(refunded.lines.first.sessionsCancelled, 4);
    final voided = sampleDetail(voidedBy: 'Nour Mahmoud');
    expect((voided.canRecordPayment, voided.canRefund, voided.canVoid, voided.canCorrect),
        (false, false, false, false));
  });

  group('refund arithmetic matches the billing plan', () {
    test('fully paid: the refund value is paid back', () {
      final draft = refund(sampleDetail(receipts: [receiptJson(1, 300000)]), 4, 180000,
          method: PaymentMethod.cash);
      expect((draft.newValueMinor, draft.paybackMinor, draft.dueAfterMinor), (120000, 180000, 0));
    });
    test('part paid: the refund clears the debt with nothing paid back', () {
      final draft = refund(sampleDetail(receipts: [receiptJson(1, 100000)]), 4, 200000);
      expect((draft.newValueMinor, draft.paybackMinor, draft.dueAfterMinor), (100000, 0, 0));
    });
    test('part paid: a smaller refund leaves a balance', () {
      final draft = refund(sampleDetail(receipts: [receiptJson(1, 100000)]), 4, 180000);
      expect((draft.paybackMinor, draft.dueAfterMinor), (0, 20000));
    });
  });

  test('commands carry the invoice version and only what the database expects', () {
    final invoice = sampleDetail(receipts: [receiptJson(1, 300000)]);
    final action = InvoiceAction.refund(refund(invoice, 4, 180000, method: PaymentMethod.visa));
    expect(action.kind.dbValue, 'refund_create');
    expect(action.toPayload(), {
      'id': 'invoice-42', 'version': 3,
      'lines': [{'line_id': 'line-1', 'sessions': 4, 'value_minor': 180000}],
      'payback_minor': 180000, 'payback_method': 'visa', 'branch': 'tagamoa',
      'reason': 'Patient is travelling',
    });
    // No payback means no method, whatever was selected earlier.
    final debtOnly = InvoiceAction.refund(
      refund(sampleDetail(), 0, 50000, method: PaymentMethod.cash),
    ).toPayload();
    expect((debtOnly['payback_minor'], debtOnly['payback_method']), (0, null));
    final receipt = invoice.receipts.single;
    final voidIt = InvoiceAction.voidReceipt(invoice, receipt, ' Wrong amount ');
    expect(voidIt.toPayload(), {
      'id': 'invoice-42', 'version': 3, 'receipt_id': 'receipt-1', 'reason': 'Wrong amount',
    });
    expect(voidIt.kind.needsManage, isTrue);
    expect(InvoiceActionKind.receiptCreate.needsManage, isFalse);
  });

  test('refunds and corrections are for payment staff only', () {
    for (final path in [
      AppRoutes.invoiceRefundLocation('patient-1', 'invoice-1'),
      AppRoutes.invoiceCorrectLocation('patient-1', 'invoice-1'),
    ]) {
      expect(authRedirect(AsyncData(frontDesk), Uri.parse(path)), AppRoutes.allAppointments);
      expect(authRedirect(AsyncData(cashier), Uri.parse(path)), isNull);
    }
    final detail = Uri.parse(AppRoutes.invoiceDetailLocation('patient-1', 'invoice-1'));
    expect(authRedirect(AsyncData(frontDesk), detail), isNull);
  });

  test('invoice, receipt and refund documents render as PDF', () async {
    final invoice = refundedDetail;
    for (final bytes in [
      await InvoiceDocumentPdf.render(invoice),
      await InvoiceDocumentPdf.render(invoice, receipt: invoice.receipts.single),
      await InvoiceDocumentPdf.render(invoice, refund: invoice.refunds.single),
      await InvoiceDocumentPdf.render(sampleDetail(voidedBy: 'Nour Mahmoud')),
    ]) {
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    }
  });
}
