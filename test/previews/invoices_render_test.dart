import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../fixtures/new_invoice_harness.dart';
import '../fixtures/service_catalog_fixture.dart';
import '../fixtures/workspace_harness.dart';
import 'ui_polish_capture.dart';

/// Payments tab and new-invoice form at phone, desktop and enlarged-dark sizes.
/// Pass `--dart-define=UI_POLISH_CAPTURE=dir` to save PNGs for review.
void main() {
  setUpAll(loadPolishFonts);
  const t = AppStrings.invoices;
  const sizes = <(String, double, bool, double)>[
    ('phone', 390, false, 1),
    ('desktop', 1440, false, 1),
    ('dark-large-text', 360, true, 1.6),
  ];
  for (final (name, width, dark, scale) in sizes) {
    testWidgets('payments tab renders on $name', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: WorkspaceHarness(role: 'reception', dark: dark, scale: scale),
      ));
      await tester.pumpAndSettle();
      final tab = find.text(AppStrings.payments).first;
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text('TG-00042'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoices-tab-$name');
    });

    testWidgets('new invoice form renders on $name', (tester) async {
      final key = await pumpNewInvoice(tester, repo: FakeInvoiceRepository(), user: cashier,
          width: width, dark: dark, textScale: scale);
      for (final service in ['6 PT sessions', '6 spinal traction sessions']) {
        await tester.ensureVisible(find.widgetWithText(OutlinedButton, t.addLine));
        await tester.tap(find.widgetWithText(OutlinedButton, t.addLine));
        await tester.pumpAndSettle();
        await tester.tap(find.text(service).last);
        await tester.pumpAndSettle();
      }
      final cash = find.descendant(
        of: find.widgetWithText(LabeledFormField, t.cash),
        matching: find.byType(TextField),
      );
      await tester.enterText(cash, '1000');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.summary).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'invoice-new-$name');
    });
  }
}
