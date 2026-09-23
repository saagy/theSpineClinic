import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payment_entry.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payments.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';

import '../../fixtures/workspace_overrides.dart';
import '../../previews/ui_polish_capture.dart';

const reason =
    'Comprehensive Rehabilitation Package (12 PT Sessions + 6 Traction)';
final payments = [
  PaymentRecord(
    id: 'long-payment',
    patientId: 'patient-fixture',
    amount: 4200,
    totalPrice: 4800,
    reason: reason,
    recordedAt: DateTime(2026, 9, 1),
  ),
  PaymentRecord(
    id: 'large-payment',
    patientId: 'patient-fixture',
    amount: 290028,
    reason: 'PT Session',
    recordedAt: DateTime(2026, 8, 30),
  ),
];

void main() {
  setUpAll(loadPolishFonts);

  for (final (width, scale, dark) in [
    (320.0, 1.0, false),
    (390.0, 1.0, false),
    (390.0, 1.0, true),
    (390.0, 1.8, false),
    (800.0, 1.0, false),
    (1280.0, 1.0, false),
  ]) {
    testWidgets(
      'payments remain readable at $width, scale $scale, dark $dark',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith(
                () => WorkspaceUser('reception-payments'),
              ),
              patientPaymentsProvider(
                'patient-fixture',
              ).overrideWith((ref) async => payments),
            ],
            child: MaterialApp(
              theme: AppTheme.light(clinicalBluePaletteLight),
              darkTheme: AppTheme.dark(clinicalBluePaletteDark),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: key,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.clinicalContentMaxWidth,
                          ),
                          child: const WorkspacePayments(
                            patientId: 'patient-fixture',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final firstEntry = find.byType(WorkspacePaymentEntry).first;
        final title = find.descendant(
          of: firstEntry,
          matching: find.text(reason),
        );
        final amount = find.descendant(
          of: firstEntry,
          matching: find.text('4,200 EGP'),
        );
        final collect = find.descendant(
          of: firstEntry,
          matching: find.text(AppStrings.collectDue),
        );
        expect(title, findsOneWidget);
        expect(collect, findsOneWidget);
        expect(
          tester
              .getSize(
                find.ancestor(of: collect, matching: find.byType(TextButton)),
              )
              .height,
          greaterThanOrEqualTo(44),
        );
        if (width < 720) {
          expect(tester.getSize(title).width, greaterThan(200));
          expect(
            tester.getTopLeft(amount).dy,
            greaterThan(tester.getTopLeft(title).dy),
          );
        } else {
          expect(
            tester.getTopLeft(amount).dx,
            greaterThan(tester.getTopLeft(title).dx),
          );
        }
        await capturePolish(tester, key, 'payments-$width-$scale-$dark');
      },
    );
  }
}
