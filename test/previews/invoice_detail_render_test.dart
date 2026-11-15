import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../fixtures/invoice_detail_fixture.dart';
import '../fixtures/invoice_detail_harness.dart';
import '../fixtures/service_catalog_fixture.dart';
import 'ui_polish_capture.dart';

/// Invoice detail, payment dialog, refund and correction forms at phone,
/// desktop and enlarged-dark sizes.
/// Pass `--dart-define=UI_POLISH_CAPTURE=dir` to save PNGs for review.
void main() {
  setUpAll(loadPolishFonts);
  const t = AppStrings.invoiceDetail;
  const sizes = <(String, double, bool, double)>[
    ('phone', 390, false, 1),
    ('desktop', 1440, false, 1),
    ('dark-large-text', 360, true, 1.6),
  ];
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final (name, width, dark, scale) in sizes) {
    Future<GlobalKey> open(WidgetTester tester, {bool refunded = false}) {
      final detail = refunded ? refundedDetail : partPaidDetail;
      return pumpInvoiceDetail(tester, repo: FakeInvoiceRepository(details: {detail.id: detail}),
          user: cashier, width: width, dark: dark, textScale: scale);
    }

    testWidgets('invoice detail renders on $name', (tester) async {
      final key = await open(tester);
      expect(find.text(t.receipt('TG-00031')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-detail-$name');
      await tap(tester, find.widgetWithText(FilledButton, t.recordPayment));
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-payment-$name');
    });

    testWidgets("cancelling an earlier day's payment warns on $name", (tester) async {
      final key = await open(tester);
      await tap(tester, find.byTooltip(AppStrings.moreActions).first);
      await tap(tester, find.text(t.voidAction));
      expect(find.textContaining("changes that day's totals"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-past-day-void-$name');
    });

    testWidgets('refunded invoice renders on $name', (tester) async {
      final key = await open(tester, refunded: true);
      expect(find.text(t.refundNumber('TG-00004')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-refunded-$name');
    });

    testWidgets('refund form renders on $name', (tester) async {
      final key = await open(tester);
      await tap(tester, find.widgetWithText(OutlinedButton, t.refund));
      await tap(tester, find.byTooltip(t.increaseSessions));
      final value = find.descendant(
        of: find.widgetWithText(LabeledFormField, t.refundValue).first,
        matching: find.byType(TextField),
      );
      await tester.enterText(value, '2000');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-refund-$name');
    });

    testWidgets('discount form renders on $name', (tester) async {
      final key = await open(tester);
      await tap(tester, find.widgetWithText(OutlinedButton, AppStrings.invoiceDiscount.addDiscount));
      final percent = find.descendant(
        of: find.widgetWithText(LabeledFormField, AppStrings.invoices.discountPercentLabel).first,
        matching: find.byType(TextField),
      );
      await tester.enterText(percent, '10');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-discount-$name');
    });

    testWidgets('discounted invoice renders on $name', (tester) async {
      final detail = sampleDetail(
        receipts: [receiptJson(31, 300000)],
        refunds: [discountJson(5, value: 30000, payback: 30000)],
      );
      final key = await pumpInvoiceDetail(tester, repo: FakeInvoiceRepository(details: {detail.id: detail}),
          user: cashier, width: width, dark: dark, textScale: scale);
      expect(find.text(AppStrings.invoiceDiscount.number('TG-00005')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-discounted-$name');
    });

    testWidgets('correction form renders on $name', (tester) async {
      final key = await open(tester);
      await tap(tester, find.byTooltip(AppStrings.moreActions).last);
      await tap(tester, find.text(t.correctInvoice));
      expect(find.text(t.alreadyPaid), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-correct-$name');
    });
  }
}
