import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/money.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_draft.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/new_invoice_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';

const t = AppStrings.invoices;

Future<void> fill(WidgetTester tester, String label, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.widgetWithText(LabeledFormField, label),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pumpAndSettle();
}

Future<void> addService(WidgetTester tester, String name) async {
  await tester.tap(find.widgetWithText(OutlinedButton, t.addLine));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Finder get createButton => find.widgetWithText(FilledButton, t.createInvoice);

void main() {
  test('draft arithmetic matches the database rounding', () {
    final pt6 = catalogFixture[1];
    final draft = InvoiceDraft(
      patientId: 'p',
      branch: ClinicLocation.tagamoa,
      invoiceDate: DateTime(2026, 11, 10),
      lines: [InvoiceLineDraft(service: pt6, quantity: 2)],
      discountKind: DiscountKind.percent,
      discountValue: 1250,
      cashMinor: 100000,
    );
    expect(draft.subtotalMinor, 480000);
    expect(draft.discountMinor, 60000);
    expect(draft.dueAfterMinor, 320000);
    expect(draft.toPayload()['discount'], {'kind': 'percent', 'value': 1250});
    expect(draft.toPayload()['payments'], [
      {'method': 'cash', 'amount_minor': 100000},
    ]);
  });

  testWidgets('front desk issues an invoice with doctors and part payment', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpNewInvoice(tester, repo: repo, user: frontDesk);
    expect(find.text(t.sectionDiscount), findsNothing); // Discounts are payment-staff only.
    // The front desk cannot choose the invoice date: invoices are dated today.
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
    expect(find.byTooltip(t.invoiceDateToday), findsOneWidget);

    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text(t.linesRequired), findsOneWidget);

    await addService(tester, '6 PT sessions');
    expect(find.text('Dr. Mariam Khaled'), findsOneWidget); // Patient's doctor pre-filled.
    await addService(tester, '6 spinal traction sessions');
    expect(find.text(t.noDoctorCredit), findsOneWidget);
    await tester.tap(find.byTooltip(t.increase).first);
    await tester.pumpAndSettle();
    expect(find.text(t.ptSessions(12)), findsOneWidget);
    expect(find.text(t.tractionSessions(6)), findsOneWidget);

    await fill(tester, t.cash, '7000');
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text(t.paymentTooHigh), findsWidgets);
    expect(repo.created, isEmpty);

    await fill(tester, t.cash, '1000');
    await fill(tester, t.visa, '500');
    expect(find.text(Money.format(465000)), findsOneWidget); // 6150 total − 1500 paid.
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    final payload = repo.created.single.toPayload();
    expect(payload['lines'], [
      {
        'service_id': 'pt6',
        'quantity': 2,
        'unit_price_minor': 240000,
        'doctor_ids': ['staff-fixture'],
      },
      {'service_id': 'tr6', 'quantity': 1, 'unit_price_minor': 135000, 'doctor_ids': <String>[]},
    ]);
    expect(payload['payments'], [
      {'method': 'cash', 'amount_minor': 100000},
      {'method': 'visa', 'amount_minor': 50000},
    ]);
    expect(find.text(t.invoiceCreated), findsOneWidget);
    expect(find.text(patientPage), findsOneWidget);
  });

  testWidgets('payment staff can give a free 100% discount', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpNewInvoice(tester, repo: repo, user: cashier);
    // Payment staff may date an invoice before today.
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    await addService(tester, 'PT session');
    await tester.ensureVisible(find.text(t.discountPercentLabel));
    await tester.pumpAndSettle();
    await fill(tester, t.discountPercentLabel, '100');
    expect(find.text(Money.format(0)), findsWidgets);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(repo.created.single.totalMinor, 0);
  });

  testWidgets('a rejected invoice keeps the form and explains why', (tester) async {
    final repo = FakeInvoiceRepository(
      createResult: const Result.failure(
        DatabaseException(
          code: 'invoice/catalog_changed',
          message: 'catalog_changed',
          userMessageKey: 'invoice_catalog_changed',
        ),
      ),
    );
    await pumpNewInvoice(tester, repo: repo, user: cashier);
    await addService(tester, 'Initial assessment');
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text(t.errorCatalogChanged), findsOneWidget);
    expect(find.text('Initial assessment'), findsOneWidget);
  });

  testWidgets('leaving a started invoice asks first', (tester) async {
    await pumpNewInvoice(tester, repo: FakeInvoiceRepository(), user: cashier);
    await addService(tester, 'PT session');
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.discardChanges), findsOneWidget);
    await tester.tap(find.text(AppStrings.discard));
    await tester.pumpAndSettle();
    expect(find.text(patientPage), findsOneWidget);
  });
}
