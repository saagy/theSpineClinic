import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/money.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_repository.dart';
import 'package:spine_clinic_app/features/payments/domain/service_catalog_item.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/service_catalog_fixture.dart';

const t = AppStrings.invoices;

Future<void> fill(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.widgetWithText(LabeledFormField, label),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  test('money parsing and display stay exact', () {
    expect(Money.parseMinor('2,400.5'), 240050);
    expect(Money.parseMinor('0.001'), isNull);
    expect(Money.editable(240050), '2400.50');
    expect(Money.format(240000), '2,400 EGP');
  });

  testWidgets('groups active services and reveals archived ones on request', (tester) async {
    await pumpCatalog(tester, repo: FakeInvoiceRepository());
    expect(find.text(t.groupPt), findsOneWidget);
    expect(find.text(t.groupAssessments), findsOneWidget);
    expect(find.text('12 PT sessions'), findsNothing);
    expect(find.text(t.countLabel(5)), findsOneWidget);
    expect(find.text(t.notCredited), findsOneWidget);
    await tester.tap(find.text(t.showActive));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.showAll).last);
    await tester.pumpAndSettle();
    expect(find.text('12 PT sessions'), findsOneWidget);
    expect(find.text(t.archived), findsOneWidget);
  });

  testWidgets('search filters by name or type and can be cleared', (tester) async {
    await pumpCatalog(tester, repo: FakeInvoiceRepository(), width: 390);
    await tester.enterText(find.byType(TextField), 'traction');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('6 spinal traction sessions'), findsOneWidget);
    expect(find.text('PT session'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text(t.noMatches), findsOneWidget);
    await tester.tap(find.text(t.clearSearch));
    await tester.pumpAndSettle();
    expect(find.text('PT session'), findsOneWidget);
  });

  testWidgets('front desk receptionists cannot open the catalog', (tester) async {
    await pumpCatalog(tester, repo: FakeInvoiceRepository(), user: frontDesk);
    expect(find.text(t.addService), findsNothing);
    expect(find.text(t.errorDenied), findsOneWidget);
  });

  testWidgets('empty catalog offers to add the first service', (tester) async {
    await pumpCatalog(tester, repo: FakeInvoiceRepository(items: []));
    expect(find.text(t.noServices), findsOneWidget);
    expect(find.text(t.addService), findsNWidgets(2));
  });

  testWidgets('adds a traction package with derived credit and per-session price', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpCatalog(tester, repo: repo);
    await tester.tap(find.text(t.addService).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, t.addService)); // Save empty.
    await tester.pumpAndSettle();
    expect(find.text(t.nameRequired), findsOneWidget);
    expect(find.text(t.priceInvalid), findsOneWidget);
    expect(repo.saved, isEmpty);

    await fill(tester, t.name, '12 spinal traction sessions');
    await tester.tap(find.text(t.typePt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.typeTraction).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.package));
    await tester.pumpAndSettle();
    await fill(tester, t.sessionsInPackage, '12');
    await fill(tester, t.price, '2400');
    expect(find.text(t.perSession(Money.format(20000))), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, t.addService));
    await tester.pumpAndSettle();

    final draft = repo.saved.single;
    expect(draft.type, ServiceType.tractionSession);
    expect(draft.toPayload()['sessions_per_unit'], 12);
    expect(draft.priceMinor, 240000);
    expect(draft.creditsDoctors, isFalse);
    expect(find.text(t.serviceAdded), findsOneWidget);
    expect(find.text(t.groupPt), findsOneWidget); // Back on the catalog.
  });

  testWidgets('edit is disabled until something changes; errors stay on the form', (tester) async {
    final repo = FakeInvoiceRepository(
      saveResult: const Result.failure(
        DatabaseException(
          code: 'invoice/duplicate',
          message: 'duplicate',
          userMessageKey: 'invoice_duplicate',
        ),
      ),
    );
    await pumpCatalog(tester, repo: repo, location: AppRoutes.serviceFormLocation('pt6'));
    final save = find.widgetWithText(FilledButton, AppStrings.saveChanges);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.text(t.removeService), findsOneWidget);
    await fill(tester, t.price, '2500');
    expect(find.text(t.priceChangeHelp), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.saved.single.version, 1);
    expect(find.text(t.errorDuplicate), findsOneWidget);
    expect(find.text(t.editService), findsOneWidget); // Still on the form.
  });

  testWidgets('remove asks first, then reports a delete or a hide', (tester) async {
    final repo = FakeInvoiceRepository()..removal = ServiceRemoval.hidden;
    await pumpCatalog(tester, repo: repo, location: AppRoutes.serviceFormLocation('pt1'));
    await tester.ensureVisible(find.text(t.removeService));
    await tester.tap(find.text(t.removeService));
    await tester.pumpAndSettle();
    expect(find.text(t.removeTitle), findsOneWidget);
    expect(repo.removed, isEmpty);
    await tester.tap(find.text(t.removeService).last);
    await tester.pumpAndSettle();
    expect(repo.removed, ['pt1']);
    expect(find.text(t.serviceRemoved), findsOneWidget);
    expect(find.text(t.groupPt), findsOneWidget); // Back on the catalog.
  });

  testWidgets('a removed service offers Restore, which saves it as offered', (tester) async {
    final repo = FakeInvoiceRepository();
    await pumpCatalog(tester, repo: repo, location: AppRoutes.serviceFormLocation('pt12'));
    expect(find.text(t.removeService), findsNothing);
    await tester.ensureVisible(find.text(t.restoreService));
    await tester.tap(find.text(t.restoreService));
    await tester.pumpAndSettle();
    expect(repo.saved.single.active, isTrue);
    expect(find.text(t.serviceRestored), findsOneWidget);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await pumpCatalog(
      tester,
      repo: FakeInvoiceRepository(),
      location: AppRoutes.serviceFormLocation('pt1'),
    );
    await fill(tester, t.name, 'Renamed');
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.discardChanges), findsOneWidget);
    await tester.tap(find.text(AppStrings.keepEditing));
    await tester.pumpAndSettle();
    expect(find.text('Renamed'), findsOneWidget);
  });

  testWidgets('an unknown service shows a way back', (tester) async {
    await pumpCatalog(
      tester,
      repo: FakeInvoiceRepository(),
      location: AppRoutes.serviceFormLocation('gone'),
    );
    expect(find.text(t.serviceNotFound), findsOneWidget);
  });
}
