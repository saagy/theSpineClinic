import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_access.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_invoice.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_repository.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_picker.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_ui.dart';
import '../fixtures/billing_pilot.dart';
import '../fixtures/staff_editor_harness.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [320.0, 1440.0]) {
    testWidgets('patient picker pages and resets after debounced ID search at $width', (tester) async {
      final repo = _PagedDirectory();
      final captureKey = GlobalKey();
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      BillingParty? selected;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          billingRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWith(() => StaffEditorUser(staffAdmin)),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: width == 320
                ? AppTheme.dark(clinicalBluePaletteDark)
                : AppTheme.light(clinicalBluePaletteLight),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
              ),
              child: child!,
            ),
            home: Scaffold(body: Builder(builder: (context) => TextButton(
              onPressed: () async => selected = await pickBillingParty(context, BillingLookup.patient),
              child: Text(billingText.pickPatient),
            ))),
          ),
        ),
      ));
      await tester.tap(find.text(billingText.pickPatient));
      await tester.pumpAndSettle();
      expect(repo.requests, [(0, '')]);
      await capturePolish(tester, captureKey, 'billing-patient-picker-$width');
      await tester.tap(find.byTooltip(AppStrings.paginationNext));
      await tester.pumpAndSettle();
      expect(repo.requests.last, (25, ''));
      await tester.enterText(find.byType(TextField), 'ID 37');
      await tester.pump(const Duration(milliseconds: 299));
      expect(repo.requests.last, (25, ''));
      await tester.pumpAndSettle();
      expect(repo.requests.last, (0, 'ID 37'));
      await tester.tap(find.text(patient));
      await tester.pumpAndSettle();
      expect(selected?.fileNumber, 37);
      expect(tester.takeException(), isNull);
    }, skip: !BillingAccess.enabled);
  }
}

class _PagedDirectory extends BillingFixture {
  final requests = <(int, String)>[];

  @override
  Future<Result<List<BillingParty>>> lookup(
    BillingLookup kind, String query, int offset, int limit,
  ) async {
    requests.add((offset, query));
    if (query.isNotEmpty) return super.lookup(kind, query, offset, limit);
    return Result.success(List.generate(offset == 0 ? limit : 4, (index) {
      final number = offset + index + 1;
      return BillingParty(
        'demo-$number', '$patient $number',
        fileNumber: number, branch: invoiceData.branch,
      );
    }));
  }
}
