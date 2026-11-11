import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import '../fixtures/billing_report_fixture.dart';
import 'ui_polish_capture.dart';

/// Renders each billing report at phone, desktop and enlarged-dark sizes.
/// Pass `--dart-define=UI_POLISH_CAPTURE=dir` to save PNGs for review.
void main() {
  setUpAll(loadPolishFonts);
  const t = AppStrings.billingReports;
  const sizes = <(String, double, bool, double)>[
    ('phone', 390, false, 1),
    ('desktop', 1440, false, 1),
    ('desktop-dark', 1280, true, 1),
    ('dark-large-text', 360, true, 1.6),
  ];
  for (final (name, width, dark, scale) in sizes) {
    testWidgets('billing reports render on $name', (tester) async {
      final repo = FakeBillingReportRepository(json: {BillingReportKind.money: moneyJson(count: 12)});
      final key = await pumpBilling(tester, repo: repo, width: width, height: 1400, dark: dark, textScale: scale);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'reports-money-$name');
      for (final (file, tab) in [
        ('revenue', t.revenue),
        ('doctor', t.doctor),
        ('doctors', t.doctors),
        ('outstanding', t.outstanding),
        ('services', t.services),
      ]) {
        final target = find.text(tab).first;
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        if (file == 'doctor') {
          ProviderScope.containerOf(tester.element(find.byType(BillingScreen)))
              .read(billingReportFilterControllerProvider.notifier)
              .setDoctor('d1', 'Dr. Ahmed Hassan');
          await tester.pumpAndSettle();
        }
        if (file == 'services') {
          await tester.tap(find.text('6 PT sessions'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: '$file on $name');
        await capturePolish(tester, key, 'reports-$file-$name');
      }
    });
  }
}
