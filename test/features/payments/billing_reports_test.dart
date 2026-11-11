import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_report_data.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_csv.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_pdf.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_view.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_views.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import '../../fixtures/billing_report_fixture.dart';
import '../../fixtures/service_catalog_fixture.dart';

const t = AppStrings.billingReports;

BillingReportFilterController controller(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(BillingScreen)),
).read(billingReportFilterControllerProvider.notifier);

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  test('periods resolve to inclusive clinic days', () {
    final now = DateTime(2026, 3, 1, 15, 30);
    ReportRange of(ReportPeriod period) => ReportRange.of(period, now);
    expect(of(ReportPeriod.today), ReportRange(DateTime(2026, 3, 1), DateTime(2026, 3, 1)));
    expect(of(ReportPeriod.yesterday).from, DateTime(2026, 2, 28));
    expect(of(ReportPeriod.last7Days).from, DateTime(2026, 2, 23));
    expect(of(ReportPeriod.thisMonth), ReportRange(DateTime(2026, 3, 1), DateTime(2026, 3, 1)));
    expect(of(ReportPeriod.lastMonth), ReportRange(DateTime(2026, 2, 1), DateTime(2026, 2, 28)));
    expect(ReportRange(DateTime(2025, 1, 1), DateTime(2026, 1, 2)).isValid, isTrue);
    expect(ReportRange(DateTime(2025, 1, 1), DateTime(2026, 1, 3)).isValid, isFalse);
    expect(ReportRange(DateTime(2026, 1, 2), DateTime(2026, 1, 1)).isValid, isFalse);
  });

  test('queries send the doctor only to reports that use one', () {
    final range = ReportRange(DateTime(2026, 11, 1), DateTime(2026, 11, 11));
    final revenue = BillingReportQuery(
      kind: BillingReportKind.revenue, range: range, branch: ClinicLocation.masrElgedida, doctorId: 'd1',
    );
    expect(revenue.toParams(), {
      'p_kind': 'revenue', 'p_from': '2026-11-01', 'p_to': '2026-11-11',
      'p_branch': 'masr_elgedida', 'p_doctor': 'd1',
    });
    const filter = BillingReportFilter(kind: BillingReportKind.doctors, doctorId: 'd1');
    expect(filter.query(DateTime(2026, 11, 11))!.toParams()['p_doctor'], isNull);
    expect(const BillingReportFilter(kind: BillingReportKind.doctor).query(DateTime(2026)), isNull);
  });

  test('money report parses, nets and exports with safe cells', () {
    final json = moneyJson();
    (json['rows'] as List).first['patient_name'] = '=HYPERLINK("x")';
    final report = MoneyReport.fromJson(json);
    expect(report.netCashMinor, 555000);
    expect(report.netVisaMinor, 420000);
    expect(report.rows[4].signedMinor, -65000);
    expect(report.isTruncated, isFalse);
    final view = buildReportView(report);
    expect(view.figures.first.value, '5,550 EGP');
    final lines = billingReportCsv(view.export).split('\r\n');
    expect(lines.first, startsWith('﻿"${t.colWhen}","${t.colDocument}","${t.colPatient}"'));
    expect(lines.first, contains('"${t.colInvoice}","${t.colBranch}"'));
    expect(lines[1], contains('"\'=HYPERLINK(""x"")"'));
    expect(lines[1], contains('"1040","TG-00040","Tagamoa"'));
    expect(lines[5], endsWith('"-650"'));
    expect(lines.length, 8);
  });

  test('doctor shares, services detail and outstanding totals reach the view', () {
    final doctor = buildReportView(parseReport(BillingReportKind.doctor, revenueJson(doctor: true)));
    expect(doctor.figures.first.label, t.doctorShare);
    expect(doctor.export.rows.last.cells.last.csv, '-900');
    final doctors = parseReport(BillingReportKind.doctors, doctorsJson) as DoctorsReport;
    expect(doctors.clinicOnlyMinor, 120000);
    expect(buildReportView(doctors).sections.single.sheet.rows.last.cells.first.text, t.noDoctorCredit);
    final services = buildReportView(parseReport(BillingReportKind.services, servicesJson));
    expect(services.sections.single.sheet.rows.first.detail!.rows, hasLength(2));
    expect(services.export.rows, hasLength(3));
    expect(services.export.rows.first.cells.first.text, '6 PT sessions');
    final outstanding = buildReportView(parseReport(BillingReportKind.outstanding, outstandingJson));
    expect(outstanding.figures.first.tone, ReportTone.warning);
    expect(outstanding.sections.single.sheet.rows.first.cells[2].csv, '2026-10-02');
  });

  testWidgets('a report prints as an A4 document', (tester) async {
    final view = buildReportView(MoneyReport.fromJson(moneyJson(count: 120)));
    final bytes = await tester.runAsync(() => BillingReportPdf.render(
      title: t.money, period: 'Nov 11, 2026', scope: t.allBranches, view: view,
    ));
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
  });

  testWidgets('daily money shows totals, movements, staff and the void log', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo);
    expect(repo.queries.single.kind, BillingReportKind.money);
    expect(repo.queries.single.range, ReportRange.of(ReportPeriod.today, DateTime.now()));
    expect(find.text('5,550 EGP'), findsOneWidget);
    expect(find.text(t.sectionMovements), findsOneWidget);
    expect(find.text('− 650 EGP'), findsOneWidget);
    expect(find.text(t.sectionStaff), findsOneWidget);
    expect(find.text('Entered twice by mistake at the front desk'), findsOneWidget);
    await tester.tap(find.text('Receipt TG-00100'));
    await tester.pumpAndSettle();
    expect(find.text('invoice invoice-0'), findsOneWidget);
  });

  testWidgets('period and branch changes request a new report', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, width: 390);
    await tester.tap(find.text(t.today));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lastMonth).last);
    await tester.pumpAndSettle();
    expect(repo.queries.last.range, ReportRange.of(ReportPeriod.lastMonth, DateTime.now()));
    await tester.tap(find.text(t.allBranches));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.clinicTagamoa).last);
    await tester.pumpAndSettle();
    expect(repo.queries.last.branch, ClinicLocation.tagamoa);
    expect(find.text('Sara Ahmed Mostafa'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('doctor revenue waits for a doctor, then keeps it for revenue', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo);
    await openTab(tester, t.doctor);
    expect(find.text(t.pickDoctor), findsOneWidget);
    expect(repo.queries.any((query) => query.kind == BillingReportKind.doctor), isFalse);
    controller(tester).setDoctor('d1', 'Dr. Ahmed Hassan');
    await tester.pumpAndSettle();
    expect(repo.queries.last.doctorId, 'd1');
    expect(find.text('2,100 EGP'), findsOneWidget);
    await openTab(tester, t.revenue);
    expect(repo.queries.last.kind, BillingReportKind.revenue);
    expect(repo.queries.last.doctorId, 'd1');
    await tester.tap(find.byTooltip(t.clearDoctor));
    await tester.pumpAndSettle();
    expect(repo.queries.last.doctorId, isNull);
    expect(find.text(t.allDoctors), findsOneWidget);
  });

  testWidgets('outstanding rows open the patient and services expand', (tester) async {
    await pumpBilling(tester, repo: FakeBillingReportRepository(), width: 390);
    await openTab(tester, t.services);
    expect(find.text('Omar Khaled'), findsNothing);
    await tester.tap(find.text('6 PT sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Omar Khaled'), findsOneWidget);
    await openTab(tester, t.outstanding);
    expect(find.textContaining(t.asOfNow, findRichText: true), findsOneWidget);
    expect(find.text(t.today), findsNothing);
    await tester.tap(find.text('Mona Abdel Rahman El Sayed'));
    await tester.pumpAndSettle();
    expect(find.text('patient patient-2'), findsOneWidget);
  });

  testWidgets('long reports page through rows and flag capped data', (tester) async {
    final repo = FakeBillingReportRepository(
      json: {BillingReportKind.money: moneyJson(count: 120, rowCount: 9000)},
    );
    await pumpBilling(tester, repo: repo, height: 6000);
    expect(find.text(t.truncated(120, 9000)), findsOneWidget);
    expect(find.text('Receipt TG-00100'), findsOneWidget);
    expect(find.text('Receipt TG-00150'), findsNothing);
    await tester.tap(find.text(AppStrings.paginationNext));
    await tester.pumpAndSettle();
    expect(find.text('Receipt TG-00150'), findsOneWidget);
    expect(find.text('Receipt TG-00100'), findsNothing);
    expect(AppSizes.reportPageSize, 50);
  });

  testWidgets('an empty period, a failure and a retry are all explicit', (tester) async {
    final repo = FakeBillingReportRepository(
      json: {BillingReportKind.money: moneyJson(count: 0)..['voids'] = <Object>[]},
      failure: const Result.failure(NetworkException(code: 'network', message: 'offline')),
    );
    await pumpBilling(tester, repo: repo);
    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(find.text(t.empty), findsNothing);
    repo.failure = null;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(t.empty), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, t.export)).onPressed, isNull);
  });

  testWidgets('front desk receptionists cannot open reports', (tester) async {
    final repo = FakeBillingReportRepository();
    await pumpBilling(tester, repo: repo, user: frontDesk);
    expect(find.text(AppStrings.invoices.errorDenied), findsOneWidget);
    expect(find.text(t.money), findsNothing);
    expect(repo.queries, isEmpty);
  });
}
