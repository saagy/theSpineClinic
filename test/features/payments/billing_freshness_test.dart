import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_workspace_tab.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_action.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_draft.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_documents.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_view.dart';
import 'package:spine_clinic_app/features/payments/presentation/invoice_detail_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/invoice_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/report_table.dart';
import '../../fixtures/billing_report_fixture.dart';
import '../../fixtures/invoice_detail_fixture.dart';
import '../../fixtures/invoice_detail_harness.dart';
import '../../fixtures/profile_editor_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';
import '../../fixtures/staff_editor_harness.dart';
import '../../fixtures/workspace_data.dart';

const t = AppStrings.invoiceDetail;

ReportSheet _sheet(List<String> names) => ReportSheet(
  columns: const [ReportColumn('Name', role: ReportCellRole.title)],
  rows: [
    for (final name in names)
      ReportRow(
        [ReportCell(name)],
        detail: ReportSheet(
          columns: const [ReportColumn('Line')],
          rows: [ReportRow([ReportCell('$name line')])],
        ),
      ),
  ],
);

void main() {
  test('changing an invoice reloads every open Billing report', () async {
    final reports = FakeBillingReportRepository();
    final container = ProviderContainer(
      overrides: [
        invoiceRepositoryProvider.overrideWithValue(
          FakeInvoiceRepository(details: {partPaidDetail.id: partPaidDetail}),
        ),
        billingReportRepositoryProvider.overrideWithValue(reports),
        currentUserProvider.overrideWith(() => StaffEditorUser(cashier)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final query = BillingReportQuery(
      kind: BillingReportKind.money,
      range: ReportRange.of(ReportPeriod.today, DateTime.now()),
    );
    container.listen(billingReportProvider(query), (_, _) {});
    await container.read(billingReportProvider(query).future);
    expect(reports.queries, hasLength(1));

    await container
        .read(invoiceActionControllerProvider.notifier)
        .run(
          InvoiceAction.recordPayment(
            partPaidDetail,
            amountMinor: 50000,
            method: PaymentMethod.cash,
            branch: ClinicLocation.tagamoa,
          ),
        );
    await container.read(billingReportProvider(query).future);
    expect(reports.queries, hasLength(2));

    await container
        .read(invoiceCreateControllerProvider.notifier)
        .create(
          InvoiceDraft(
            patientId: workspacePatient.id,
            branch: ClinicLocation.tagamoa,
            invoiceDate: DateTime.now(),
            lines: const [],
          ),
        );
    await container.read(billingReportProvider(query).future);
    expect(reports.queries, hasLength(3));
  });

  testWidgets('Billing reloads in place after the person comes back to it', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final auth = ProfileEditorRepository();
    auth.user = auth.user!.copyWith(role: UserRole.receptionist, canManagePayments: true);
    final reports = FakeBillingReportRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sharedPreferencesProvider.overrideWithValue(preferences),
        invoiceRepositoryProvider.overrideWithValue(FakeInvoiceRepository()),
        billingReportRepositoryProvider.overrideWithValue(reports),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final router = container.read(routerProvider);
    router.go(AppRoutes.billing);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(reports.queries, hasLength(1)); // Entry loads once.

    router.push(AppRoutes.serviceCatalog);
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(reports.queries, hasLength(2));
    expect(find.byType(ReportTable), findsWidgets); // No loading skeleton swap.

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Riverpod starts the reload from a zero-length timer after the frame.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(reports.queries, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reloaded report keeps its page and open rows', (tester) async {
    final names = [for (int i = 0; i < AppSizes.reportPageSize + 5; i++) 'Row $i'];
    Future<void> show(ReportSheet sheet) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(clinicalBluePaletteLight),
        home: Scaffold(body: SingleChildScrollView(child: ReportTable(sheet: sheet))),
      ),
    );
    await show(_sheet(names));
    await tester.ensureVisible(find.text(AppStrings.paginationNext));
    await tester.tap(find.text(AppStrings.paginationNext));
    await tester.pumpAndSettle();
    final String last = names.last;
    await tester.tap(find.text(last));
    await tester.pumpAndSettle();
    expect(find.text('$last line'), findsOneWidget);

    // A new row arrives at the top, as a new receipt would.
    await show(_sheet(['New row', ...names]));
    await tester.pumpAndSettle();
    expect(find.text('${AppStrings.paginationPage} 2 ${AppStrings.paginationOf} 2'), findsOneWidget);
    expect(find.text('$last line'), findsOneWidget);

    // A row that is gone no longer counts as open.
    await show(_sheet(names.take(3).toList()));
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsOneWidget);
    expect(find.text('$last line'), findsNothing);
  });

  testWidgets("an invoice opened from Billing links to the patient's payments", (tester) async {
    await pumpInvoiceDetail(
      tester,
      repo: FakeInvoiceRepository(details: {partPaidDetail.id: partPaidDetail}),
      user: cashier,
      fromBilling: true,
    );
    final link = find.byTooltip(t.openPatientPayments);
    expect(link, findsOneWidget);
    expect(find.descendant(of: link, matching: find.byIcon(Icons.chevron_right)), findsOneWidget);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text(invoicePatientPage), findsOneWidget);
    expect(find.text('tab: ${PatientWorkspaceTab.payments.name}'), findsOneWidget);
    expect(find.text(t.title('TG-00042')), findsNothing);

    // Back returns to Billing, not to the closed invoice.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text(invoiceBillingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an invoice opened from its patient has no link back to them', (tester) async {
    await pumpInvoiceDetail(
      tester,
      repo: FakeInvoiceRepository(details: {partPaidDetail.id: partPaidDetail}),
      user: cashier,
    );
    expect(find.text(t.title('TG-00042')), findsOneWidget);
    expect(find.byTooltip(t.openPatientPayments), findsNothing);
  });

  test('receptionists find Payments second; doctors have none', () {
    expect(PatientWorkspaceTab.forRole(UserRole.receptionist)[1], PatientWorkspaceTab.payments);
    expect(PatientWorkspaceTab.forRole(UserRole.superAdmin).last, PatientWorkspaceTab.payments);
    expect(PatientWorkspaceTab.forRole(UserRole.doctor), isNot(contains(PatientWorkspaceTab.payments)));
    expect(PatientWorkspaceTab.fromQuery('payments'), PatientWorkspaceTab.payments);
    expect(PatientWorkspaceTab.fromQuery('nope'), isNull);
    expect(
      AppRoutes.patientLocation('p 1', tab: 'payments'),
      '/patient/p%201?tab=payments',
    );
  });

  test('a patient record asked to show Payments selects it for the role', () async {
    final container = ProviderContainer(
      overrides: [currentUserProvider.overrideWith(() => StaffEditorUser(cashier))],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final tab = patientActiveTabProvider('p1');
    container.listen(tab, (_, _) {});
    container.read(tab.notifier).show(PatientWorkspaceTab.payments);
    expect(container.read(tab), 1);
  });
}
