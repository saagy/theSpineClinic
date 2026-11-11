import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../fixtures/service_catalog_fixture.dart';
import 'ui_polish_capture.dart';

/// Renders the catalog and editor at phone, desktop and enlarged-dark sizes.
/// Pass `--dart-define=UI_POLISH_CAPTURE=dir` to save PNGs for review.
void main() {
  setUpAll(loadPolishFonts);
  const sizes = <(String, double, bool, double)>[
    ('phone', 390, false, 1),
    ('desktop', 1440, false, 1),
    ('dark-large-text', 360, true, 1.6),
  ];
  for (final (name, width, dark, scale) in sizes) {
    testWidgets('service catalog renders on $name', (tester) async {
      final key = await pumpCatalog(tester, repo: FakeInvoiceRepository(),
          width: width, dark: dark, textScale: scale);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'services-list-$name');
    });

    testWidgets('package editor renders on $name', (tester) async {
      final key = await pumpCatalog(tester, repo: FakeInvoiceRepository(),
          width: width, dark: dark, textScale: scale,
          location: AppRoutes.serviceFormLocation('pt6'));
      final price = find.descendant(
        of: find.widgetWithText(LabeledFormField, AppStrings.invoices.price),
        matching: find.byType(TextField),
      );
      await tester.enterText(price, '2500');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'services-edit-$name');
    });
  }

  testWidgets('new service form renders on phone', (tester) async {
    final key = await pumpCatalog(tester, repo: FakeInvoiceRepository(),
        width: 390, location: AppRoutes.serviceFormLocation(null));
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'services-new-phone');
  });
}
