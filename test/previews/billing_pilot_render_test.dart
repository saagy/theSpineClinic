import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/data/billing_csv.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_access.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_invoice.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_money.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_document_output.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_register_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_ui.dart';
import '../fixtures/billing_pilot.dart';
import '../fixtures/staff_editor_harness.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

const pilot = BillingAccess.enabled;
void main() {
  setUpAll(loadPolishFonts);
  test('minor units and discount rounding remain exact', () {
    expect(parseBillingMinor(' 0.01 '), 1);
    expect(parseBillingMinor('0.009'), isNull);
    expect(parseBillingMinor('1e3'), isNull);
    expect(billingNet(5, 5000), 3);
    expect(billingNet(1000000000000, 1), 999900000000);
  });
  test('All four A4 documents render with bundled fonts', () async {
    final invoice = BillingInvoice.fromJson(row);
    final receipt = billingRows(row['movements']).single;
    final credit = BillingMovement.fromJson({
      ...receipt,
      'kind': 'return',
      'method': null,
      'amount_minor': 50000,
      'reason': 'Test return',
      'debt_reduced_minor': 40000,
      'allocations': [
        {'line_id': 'line-fixture', 'amount_minor': 50000, 'quantity': 1},
      ],
    });
    final refund = BillingMovement.fromJson({
      ...receipt,
      'kind': 'refund',
      'amount_minor': 10000,
      'reason': 'Test refund',
      'allocations': [],
    });
    for (final movement in [null, invoice.movements.single, credit, refund]) {
      final bytes = await renderBillingDocument(invoice, movement);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      const output = String.fromEnvironment('UI_POLISH_CAPTURE');
      if (output.isNotEmpty) {
        await Directory(output).create(recursive: true);
        await File(
          '$output/billing-${movement?.kind.name ?? 'invoice'}.pdf',
        ).writeAsBytes(bytes);
      }
    }
  });
  test(
    'CSV uses the same minor-unit totals and escapes spreadsheet formulas',
    () {
      final csv = billingCsv([
        {...row, 'patient_name': '=1+1'},
      ], collections: false);
      expect(csv, contains('"1000.00","600.00","0.00","0.00","400.00","0.00"'));
      expect(csv, contains('"\'=1+1"'));
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets('create and review a draft at $width', (tester) async {
      final repo = BillingFixture();
      final key = await _pump(tester, repo, width);
      Future<void> press(Finder target) async {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await press(find.text(billingText.allBranches));
      await capturePolish(tester, key, 'billing-branch-menu-$width');
      await press(find.text(ClinicLocation.masrElgedida.displayLabel));
      expect(repo.lastFilter?.branch, ClinicLocation.masrElgedida);
      await press(find.text(ClinicLocation.masrElgedida.displayLabel));
      await press(find.text(billingText.allBranches));
      expect(repo.lastFilter?.branch, isNull);
      await press(find.text(billingText.allStatuses));
      await press(find.text(billingStatusLabel(BillingStatus.draft)).last);
      expect(repo.lastFilter?.status, BillingStatus.draft);
      await press(find.text(billingStatusLabel(BillingStatus.draft)).first);
      await press(find.text(billingText.allStatuses));
      expect(repo.lastFilter?.status, isNull);

      await press(find.text(billingText.newInvoice));
      await press(find.text(billingText.pickPatient));
      await press(find.textContaining(patient).last);
      await press(find.text(billingText.pickDoctor));
      await press(find.text('Dr. Noura Hassan').last);
      await press(find.text(billingText.addService));
      await press(find.text('Physiotherapy session').last);
      expect(find.text('EGP 500.00'), findsWidgets);
      await capturePolish(tester, key, 'billing-editor-$width');
      await press(find.text(billingText.saveDraft));
      expect(repo.lastCommand?.action, BillingAction.draft);
      expect(repo.lastCommand?.payload['branch'], 'tagamoa');
      expect(tester.takeException(), isNull);
    }, skip: !pilot);
  }
  for (final width in [390.0, 1440.0, 320.0]) {
    testWidgets('billing register and receipt recovery at $width', (
      tester,
    ) async {
      final repo = BillingFixture();
      final key = await _pump(tester, repo, width);
      await capturePolish(tester, key, 'billing-register-$width');
      await tester.tap(find.textContaining(patient).first);
      await tester.pumpAndSettle();
      await capturePolish(tester, key, 'billing-invoice-$width');
      final collect = find.text(billingText.collect);
      await tester.ensureVisible(collect);
      await tester.tap(collect);
      await tester.pumpAndSettle();
      await capturePolish(tester, key, 'billing-receipt-$width');
      await tester.tap(
        find.widgetWithText(FilledButton, billingText.collect).last,
      );
      await tester.pumpAndSettle();
      expect(repo.lastCommand?.payload['amount_minor'], 40000);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    }, skip: !pilot);
  }
  testWidgets('billing empty and network error states', (tester) async {
    final key = await _pump(tester, BillingFixture(empty: true), 390);
    expect(find.text(billingText.noInvoices), findsOneWidget);
    await capturePolish(tester, key, 'billing-empty-390');
    final errorKey = await _pump(tester, BillingFixture(error: true), 390);
    expect(find.text(billingText.noInvoices), findsNothing);
    await capturePolish(tester, errorKey, 'billing-error-390');
    expect(tester.takeException(), isNull);
  }, skip: !pilot);
}

Future<GlobalKey> _pump(
  WidgetTester tester,
  BillingFixture repo,
  double width,
) async {
  tester.view.physicalSize = Size(width, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: ObjectKey(repo),
      overrides: [
        billingRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(() => StaffEditorUser(staffAdmin)),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: width == 320
              ? AppTheme.dark(clinicalBluePaletteDark)
              : AppTheme.light(clinicalBluePaletteLight),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.7 : 1)),
            child: child!,
          ),
          home: const BillingRegisterScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}
